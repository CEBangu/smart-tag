//
//  smart_tagApp.swift
//  smart_tag
//
//  Created by Ciprian Bangu on 2025-03-27.
//

import UIKit
import CoreML
import Vision
import CoreImage
import CoreGraphics
import SwiftUI

struct YOLODetection {
    let bbox: CGRect
    let confidence: Float
    let classIndex: Int
    let maskCoefficients: [Float]
}

struct LetterboxedImage {
    let image: UIImage
    let scale: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat
}

func letterboxResize(image: UIImage, targetSize: CGSize = CGSize(width: 640, height: 640)) -> LetterboxedImage? {
    let originalSize = image.size
    let scale = min(targetSize.width / originalSize.width, targetSize.height / originalSize.height)
    let newSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
    let xOffset = (targetSize.width - newSize.width) / 2.0
    let yOffset = (targetSize.height - newSize.height) / 2.0

    UIGraphicsBeginImageContextWithOptions(targetSize, false, image.scale)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }

    context.setFillColor(UIColor.black.cgColor)
    context.fill(CGRect(origin: .zero, size: targetSize))
    image.draw(in: CGRect(x: xOffset, y: yOffset, width: newSize.width, height: newSize.height))

    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    guard let finalImage = resizedImage else { return nil }

    return LetterboxedImage(image: finalImage, scale: scale, xOffset: xOffset, yOffset: yOffset)
}

func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
    let attrs: [String: Any] = [
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
    ]
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        Int(size.width),
        Int(size.height),
        kCVPixelFormatType_32BGRA,
        attrs as CFDictionary,
        &pixelBuffer
    )
    guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    let context = CGContext(
        data: CVPixelBufferGetBaseAddress(buffer),
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    )

    guard let cgImage = image.cgImage else {
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        return nil
    }

    context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
    CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
    return buffer
}

func loadModel() -> MLModel? {
    guard let modelURL = Bundle.main.url(forResource: "yolo11n_segment", withExtension: "mlmodelc") else {
        print("Failed to find model in bundle")
        return nil
    }

    do {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        return try MLModel(contentsOf: modelURL, configuration: config)
    } catch {
        print("Failed to load model: \(error)")
        return nil
    }
}

func runSegmentationModel(
    model: MLModel,
    pixelBuffer: CVPixelBuffer
) async -> [UIImage] {
    do {
        let input = try MLDictionaryFeatureProvider(dictionary: ["image": MLFeatureValue(pixelBuffer: pixelBuffer)])
        let prediction = try await model.prediction(from: input)

        guard
            let var_1366 = prediction.featureValue(for: "var_1366")?.multiArrayValue,
            let p = prediction.featureValue(for: "p")?.multiArrayValue
        else {
            print("Failed to retrieve model output tensors.")
            return []
        }

        let detections = extractDetections(from: var_1366, confidenceThreshold: 0.85)
        print("Found \(detections.count) person detections")

        var softMaskImages: [UIImage] = []

        for (i, det) in detections.prefix(8).enumerated() {
            print("Processing detection \(i) → class \(det.classIndex), confidence \(det.confidence)")

            let softMask = generateMask(from: det, p: p)

            if let image = softMaskToUIImage(mask: softMask) {
                softMaskImages.append(image)
                print("Mask \(i) converted to UIImage")
            } else {
                print("Mask \(i) failed to convert to UIImage")
            }
        }

        print("Generated \(softMaskImages.count) soft masks")
        return softMaskImages

    } catch {
        print("Inference error: \(error)")
        return []
    }
}

func extractDetections(
    from var_1366: MLMultiArray,
    numClasses: Int = 80,
    maskCoeffCount: Int = 32,
    confidenceThreshold: Float = 0.1
) -> [YOLODetection] {
    let numChannels = var_1366.shape[1].intValue
    let numDetections = var_1366.shape[2].intValue
    let expectedChannels = 4 + numClasses + maskCoeffCount
    let targetClasses: Set<Int> = [0]  // Only allow 'person' class

    guard numChannels == expectedChannels else {
        print("Unexpected channel count: got \(numChannels), expected \(expectedChannels)")
        return []
    }

    var results: [YOLODetection] = []

    for i in 0..<numDetections {
        let x = getValue(var_1366, 0, 0, i)
        let y = getValue(var_1366, 0, 1, i)
        let w = getValue(var_1366, 0, 2, i)
        let h = getValue(var_1366, 0, 3, i)

        let classScores = (0..<numClasses).map { c in
            getValue(var_1366, 0, 4 + c, i)
        }

        guard let maxClassIndex = classScores.indices.max(by: { classScores[$0] < classScores[$1] }) else { continue }
        let confidence = classScores[maxClassIndex]
        if confidence < confidenceThreshold { continue }
        if !targetClasses.contains(maxClassIndex) { continue }  // Skip non-person

        print("Detection \(i): class \(maxClassIndex), conf \(confidence)")

        let maskCoeffs = (0..<maskCoeffCount).map { j in
            getValue(var_1366, 0, 4 + numClasses + j, i)
        }

        let rect = CGRect(
            x: CGFloat(x - w / 2),
            y: CGFloat(y - h / 2),
            width: CGFloat(w),
            height: CGFloat(h)
        )

        results.append(YOLODetection(
            bbox: rect,
            confidence: confidence,
            classIndex: maxClassIndex,
            maskCoefficients: maskCoeffs
        ))
    }
    let supressed = suppressOverlappingDetections(results)
    print("Extracted \(results.count) person detections")
    return supressed
}

func getValue(_ array: MLMultiArray, _ i: Int, _ j: Int, _ k: Int) -> Float {
    return array[[NSNumber(value: i), NSNumber(value: j), NSNumber(value: k)]].floatValue
}

func getPrototypeChannel(p: MLMultiArray, channel: Int) -> [[Float]] {
    let height = p.shape[2].intValue
    let width = p.shape[3].intValue

    var output = Array(repeating: Array(repeating: Float(0), count: width), count: height)
    for y in 0..<height {
        for x in 0..<width {
            output[y][x] = p[[0, NSNumber(value: channel), NSNumber(value: y), NSNumber(value: x)]].floatValue
        }
    }
    return output
}

func generateMask(from detection: YOLODetection, p: MLMultiArray) -> [[Float]] {
    let height = p.shape[2].intValue
    let width = p.shape[3].intValue
    let numChannels = detection.maskCoefficients.count

    var mask = Array(repeating: Array(repeating: Float(0), count: width), count: height)

    for c in 0..<numChannels {
        let coeff = detection.maskCoefficients[c]
        let proto = getPrototypeChannel(p: p, channel: c)
        for y in 0..<height {
            for x in 0..<width {
                mask[y][x] += coeff * proto[y][x]
            }
        }
    }

    for y in 0..<height {
        for x in 0..<width {
            mask[y][x] = 1.0 / (1.0 + exp(-mask[y][x])) // sigmoid
        }
    }

    return mask
}

func softMaskToUIImage(mask: [[Float]]) -> UIImage? {
    let height = mask.count
    let width = mask.first?.count ?? 0
    let pixelCount = height * width
    var pixels = [UInt8](repeating: 0, count: pixelCount)

    for y in 0..<height {
        for x in 0..<width {
            let value = mask[y][x]
            let clamped = max(0.0, min(1.0, value.isFinite ? value : 0.0))
            pixels[y * width + x] = UInt8(clamped * 255.0)
        }
    }

    let colorSpace = CGColorSpaceCreateDeviceGray()
    let bitsPerComponent = 8
    let bytesPerRow = width

    guard let providerRef = CGDataProvider(data: NSData(bytes: &pixels, length: pixels.count)) else {
        return nil
    }

    guard let cgImage = CGImage(
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bitsPerPixel: bitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        provider: providerRef,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    ) else {
        return nil
    }

    return UIImage(cgImage: cgImage)
}
func suppressOverlappingDetections(_ detections: [YOLODetection], iouThreshold: CGFloat = 0.5) -> [YOLODetection] {
    var kept: [YOLODetection] = []

    for det in detections.sorted(by: { $0.confidence > $1.confidence }) {
        let overlaps = kept.contains { iou($0.bbox, det.bbox) > iouThreshold }
        if !overlaps {
            kept.append(det)
        }
    }

    return kept
}

func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
    let intersection = a.intersection(b)
    if intersection.isNull || intersection.isEmpty {
        return 0.0
    }

    let intersectionArea = intersection.width * intersection.height
    let unionArea = a.width * a.height + b.width * b.height - intersectionArea
    return intersectionArea / unionArea
}
