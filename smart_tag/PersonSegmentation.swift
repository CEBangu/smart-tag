//
//  PersonSegmentation.swift
//  smart_tag
//
//  Created by Ciprian Bangu on 2025-03-30.
//

import Foundation
import Vision
import CoreImage
import UIKit
import ImageIO // Needed for orientation fix

func runPersonInstanceSegmentation(image: UIImage) async -> [UIImage] {
    guard let cgImage = image.cgImage else {
        print("❌ Failed to get CGImage from UIImage")
        return []
    }

    // ✅ Fix: preserve correct image orientation
    let orientation = CGImagePropertyOrientation(image.imageOrientation)

    let request = VNGeneratePersonInstanceMaskRequest()

    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

    do {
        try handler.perform([request])
    } catch {
        print("❌ Vision request failed: \(error)")
        return []
    }

    guard let results = request.results else {
        print("❌ No results from VNGeneratePersonInstanceMaskRequest")
        return []
    }

    var outputImages: [UIImage] = []

    for observation in results {
        for i in 0..<observation.allInstances.count {
            do {
                let pixelBuffer = try observation.generateMask(forInstances: [i])
                if let uiImage = maskToUIImage(pixelBuffer: pixelBuffer, targetSize: CGSize(width: 550, height: 750), color: .green) {
                    outputImages.append(uiImage)
                }
            } catch {
                print("❌ Failed to generate mask for instance \(i): \(error)")
            }
        }
    }

    return outputImages
}

func maskToUIImage(pixelBuffer: CVPixelBuffer, targetSize: CGSize, color: UIColor = .red) -> UIImage? {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

    // Calculate aspect fit scale and letterbox offsets
    let originalSize = ciImage.extent.size
    let scale = min(targetSize.width / originalSize.width, targetSize.height / originalSize.height)

    let scaledWidth = originalSize.width * scale
    let scaledHeight = originalSize.height * scale
    let dx = (targetSize.width - scaledWidth) / 2.0
    let dy = (targetSize.height - scaledHeight) / 2.0

    // Build the scaling and centering transform
    var transform = CGAffineTransform(scaleX: scale, y: scale)
    transform = transform.translatedBy(x: dx / scale, y: dy / scale)

    let transformed = ciImage.transformed(by: transform)

    // Convert mask to alpha
    let alphaMask = transformed.applyingFilter("CIMaskToAlpha")

    // Apply color to visible regions
    let colorImage = CIImage(color: CIColor(color: color)).cropped(to: alphaMask.extent)
    let masked = colorImage.applyingFilter("CIMultiplyCompositing", parameters: [
        "inputBackgroundImage": alphaMask
    ])

    let context = CIContext()
    guard let cgImage = context.createCGImage(masked, from: CGRect(origin: .zero, size: targetSize)) else {
        return nil
    }

    return UIImage(cgImage: cgImage)
}

// MARK: - Orientation Helper

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
