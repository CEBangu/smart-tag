//
//  smart_tagApp.swift
//  smart_tag
//
//  Created by Ciprian Bangu on 2025-03-27.
//

// TODO: transparent pop-up text box; better clicking options + shouldn't be able to long press anywhere on the screen; save co-ordinates to populate next view


import SwiftUI
import PhotosUI
import CoreGraphics

// DetectedPerson struct updated as above

struct ContentView: View {
    // Image State
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var caption = ""
    @State private var letterboxInfo: LetterboxedImage?

    // Tagging State
    @State private var detectedPeople: [DetectedPerson] = [] // Use updated struct
    @State private var selectedPersonID: UUID? = nil
    @State private var newAnnotationText: String = ""
    @State private var showAnnotationInput = false
    @State private var annotationPosition: CGPoint? = nil // Tap position relative to the image frame
    @State private var showPostDetail = false

    // Fixed Frame Size (Restored)
    let imageFrameWidth: CGFloat = 550
    let imageFrameHeight: CGFloat = 750

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .overlay(
                ZStack { // Main container for potentially positioning the popover later
                    // --- Image and Mask Display Area ---
                    if let image = selectedImage {
                        ZStack { // Container for Image, Masks, and Gesture Overlay
                            // Base Image
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit() // Image fits within the 550x750 frame

                            // Mask Visualization Layer (Restored)
                            ForEach(detectedPeople) { person in
                                // Use the stored maskImage
                                Image(uiImage: person.maskImage)
                                    .resizable()
                                    // Masks need to fill the frame because their data
                                    // corresponds to the (potentially letterboxed) input image
                                    // that conceptually fills the frame.
                                    .scaledToFill()
                                    .blendMode(.plusLighter) // Your silhouette blend mode
                                    .opacity(person.annotation == nil ? 0.35 : 0.00) // Adjust opacity
                                    .allowsHitTesting(false) // IMPORTANT: Masks don't block gestures
                            }

                            // Gesture Handling Overlay (Transparent)
                            Color.clear
                                .contentShape(Rectangle()) // Make sure it intercepts taps
                                .gesture(LongPressGesture(minimumDuration: 0.5)
                                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local)) // Capture location
                                    .onEnded { value in
                                        switch value {
                                        case .second(true, let drag):
                                            guard let location = drag?.location else { return }
                                            // Pass the location within the frame and the frame size
                                            handleTap(at: location, frameSize: CGSize(width: imageFrameWidth, height: imageFrameHeight))
                                        default:
                                            break
                                        }
                                    }
                                ) // End gesture

                        } // End Image ZStack
                        .frame(width: imageFrameWidth, height: imageFrameHeight) // Apply fixed frame
//                        .cornerRadius(120) // Apply corner radius
                        .clipped() // Clip contents
                        .offset(y: -30) // Apply offset

                    } else {
                        // Photo Picker Button (Centered)
                        Button { showPhotoPicker = true } label: {
                            VStack {
                                Image(systemName: "plus.circle").resizable().frame(width: 60, height: 60)
                                Text("Add Photo")
                            }
                            .foregroundColor(.white).padding().background(.ultraThinMaterial).cornerRadius(16)
                        }
                        // Position button if no image
                         .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 * 0.8) // Rough center
                    }

                    // --- Annotation Input Popover ---
                    if showAnnotationInput, let position = annotationPosition, let personId = selectedPersonID {
                       AnnotationInputView(
                            annotationText: $newAnnotationText,
                            // Position calculation needs care. 'position' is relative to the 550x750 frame.
                            // We need to translate that to the coordinate space of this outer ZStack.
                            // This requires knowing the frame's position (center + offset).
                            position: calculatePopoverPosition(tapPositionInFrame: position),
                            onSave: {
                                if let index = detectedPeople.firstIndex(where: { $0.id == personId }) {
                                    detectedPeople[index].annotation = newAnnotationText.isEmpty ? nil : newAnnotationText
                                }
                                resetAnnotationState()
                            },
                            onCancel: {
                                resetAnnotationState()
                            }
                       )
                       .zIndex(10) // Ensure popover is on top
                    }
                } // End Main ZStack
            )
            .overlay( // UI Elements (Buttons, Caption) - Kept separate
                VStack {
                    // Top Buttons (Restored original structure)
                     HStack(spacing: 10) { // Adjust spacing if needed
                         CircleButton(icon: "xmark") { // Reset button
                             selectedImage = nil
                             detectedPeople = []
                             letterboxInfo = nil
                             caption = ""
                             resetAnnotationState()
                         }
                         Spacer()
                        CircleButton(icon: "textformat")
                        CircleButton(icon: "face.smiling")
                        CircleButton(icon: "music.note")
                        CircleButton(icon: "sparkles")
                        CircleButton(icon: "ellipsis")
                     }
                     .padding(.horizontal)
//                     .padding(.top, (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 0 + 0) // Safer safe area

                     .padding(.top, 75)
                     .ignoresSafeArea(.container, edges: .top)
                    Spacer()

                    // Bottom UI (Caption, Send, etc.) - Restored original structure
                    VStack(spacing: 12) {
                         ZStack(alignment: .leading) { // Original caption styling
                             if caption.isEmpty {
                                 Text("Add a caption...")
                                     .bold()
                                     .foregroundColor(.white.opacity(0.6)) // Slightly dimmed placeholder
                                     .padding(.leading, 16) // Match TextField padding
                             }
                             TextField("", text: $caption)
                                 .foregroundColor(.white)
                                 .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)) // Adjust padding
                                 .background(Color.black.opacity(0.3)) // Example background
                                 .cornerRadius(20) // Example corner radius
                         }
                         .padding(.horizontal)


                        HStack(spacing: 12) {
                            StoryButton(title: "Your story", image: "person.crop.circle")
                            StoryButton(title: "Close Friends", image: "star.circle.fill", isGreen: true)
                            Button(action: { print("Send tapped - Triggering PostDetailView presentation")
                                if selectedImage != nil {
                                    showPostDetail = true
                                }}) {
                                Circle() // Original Send button style
                                    .fill(Color.white)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.black)
                                    )
                            }
                                .disabled(selectedImage == nil)
                        }
//                        .padding(.bottom, (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom ?? 0 + 0)
                        .padding(.bottom, 5)
                        .ignoresSafeArea(.container, edges: .bottom)
                    }
                } // End UI Overlay VStack
                 .allowsHitTesting(selectedImage != nil) // Only allow UI interaction if image exists? Optional.
            )
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self),
                          let uiImage = UIImage(data: data) else { return }

                    // Reset state
                    selectedImage = uiImage
                    detectedPeople = []
                    letterboxInfo = nil
                    caption = ""
                    resetAnnotationState()

                    // --- Perform Segmentation ---
                    guard let resized = letterboxResize(image: uiImage),
                          let buffer = pixelBuffer(from: resized.image, size: CGSize(width: 640, height: 640)),
                          let model = loadModel() else {
                        print("Preprocessing or model loading failed")
                        return
                    }

                    self.letterboxInfo = resized
                    let segmentationResults = await runSegmentationModel(model: model, pixelBuffer: buffer)

                    // Create DetectedPerson objects, ensuring maskImage exists
                    self.detectedPeople = segmentationResults.compactMap { result in
                        guard let img = result.maskImage else {
                            print("Warning: Failed to create UIImage for one mask.")
                            return nil // Skip if UIImage failed
                        }
                        return DetectedPerson(
                            maskData: result.maskData,
                            maskImage: img, // Store the UIImage
                            modelInputBoundingBox: result.detection.bbox,
                            letterboxInfo: resized,
                            originalImageSize: uiImage.size
                        )
                    }
                    print("Processed \(self.detectedPeople.count) people for tagging.")
                }

            }
            .fullScreenCover(isPresented: $showPostDetail) {
                if let imageToPost = selectedImage {
                    PostDetailView(image: imageToPost, taggedPeople: detectedPeople)
                } else {
                    Text("error: image not available.")
                        .onAppear {
                            showPostDetail = false
                        }
                }
            }
            // AnnotationInputView is now placed conditionally within the main ZStack
    }

    func resetAnnotationState() {
        showAnnotationInput = false
        selectedPersonID = nil
        newAnnotationText = ""
        annotationPosition = nil
    }

    // --- Helper to Calculate Popover Position ---
    func calculatePopoverPosition(tapPositionInFrame: CGPoint) -> CGPoint {
        // 1. Find the center of the screen (approaximation)
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // 2. Calculate the image frame's origin relative to the screen center
        //    (considering the frame size and the offset)
        //    NOTE: This assumes the ZStack is centered. Adjust if ZStack has other positioning.
        let frameOriginX = (screenWidth - imageFrameWidth) / 2
        let frameOriginY = (screenHeight / 2) - (imageFrameHeight / 2) - 30 // Center Y - Half Height + Offset Y

        // 3. Calculate the tap's absolute position on the screen
        let absoluteTapX = frameOriginX + tapPositionInFrame.x
        let absoluteTapY = frameOriginY + tapPositionInFrame.y

        // 4. Return position slightly adjusted (e.g., above the tap)
        //    This position is used by the .position() modifier on AnnotationInputView,
        //    which is relative to its parent container (the main ZStack).
        //    If the main ZStack fills the screen, this absolute position works directly.
        return CGPoint(x: absoluteTapX, y: absoluteTapY - 60) // Offset popover above tap
    }


    // --- Updated handleTap Function ---
    private func handleTap(at location: CGPoint, frameSize: CGSize) {
        // location is the tap point within the 550x750 frame.
        // frameSize is CGSize(width: 550, height: 750).
        guard let lbInfo = letterboxInfo,
              selectedImage != nil,
              let originalSize = selectedImage?.size,
              originalSize != .zero else {
            print("Missing data for hit test.")
            return
        }

        // --- Coordinate Conversion: Tap in Frame -> Model Input (640x640) ---

        // 1. Determine the actual image content's rect *within* the fixed frame (due to scaledToFit)
        let frameAspect = frameSize.width / frameSize.height
        let originalAspect = originalSize.width / originalSize.height
        var imageRectInFrame: CGRect = .zero

        if frameAspect > originalAspect { // Frame wider than image: image height fits, width centered
            let scaledWidth = originalSize.width * (frameSize.height / originalSize.height)
            imageRectInFrame = CGRect(x: (frameSize.width - scaledWidth) / 2.0, y: 0, width: scaledWidth, height: frameSize.height)
        } else { // Frame taller than image: image width fits, height centered
            let scaledHeight = originalSize.height * (frameSize.width / originalSize.width)
            imageRectInFrame = CGRect(x: 0, y: (frameSize.height - scaledHeight) / 2.0, width: frameSize.width, height: scaledHeight)
        }

        // 2. Check if tap is within the actual scaled image bounds inside the frame
        guard imageRectInFrame.contains(location) else {
            print("Tap location \(location) is outside the scaled image rect \(imageRectInFrame) within the frame.")
            return
        }

        // 3. Convert tap location within frame -> location relative to the image content's top-left (0,0)
        let tapX_relative = location.x - imageRectInFrame.origin.x
        let tapY_relative = location.y - imageRectInFrame.origin.y

        // 4. Convert relative tap location -> location in original image coordinates
        let scaleToFit = min(imageRectInFrame.width / originalSize.width, imageRectInFrame.height / originalSize.height)
        guard scaleToFit > 0 else { return } // Avoid division by zero
        let tapX_in_Image = tapX_relative / scaleToFit
        let tapY_in_Image = tapY_relative / scaleToFit

        // 5. Convert original image coordinates -> model input coordinates (with letterbox)
        let tapX_in_Model = tapX_in_Image * lbInfo.scale + lbInfo.xOffset
        let tapY_in_Model = tapY_in_Image * lbInfo.scale + lbInfo.yOffset
        let modelTapPoint = CGPoint(x: tapX_in_Model, y: tapY_in_Model)

        // --- Hit Test Against Masks (using raw maskData) ---
        for person in detectedPeople.reversed() { // Check visually topmost first
            let modelBox = person.modelInputBoundingBox
            let maskData = person.maskData
            let maskHeight = maskData.count
            let maskWidth = maskData.first?.count ?? 0
            guard maskWidth > 0, maskHeight > 0 else { continue }

            if modelBox.contains(modelTapPoint) {
                let maskCoordX = (modelTapPoint.x - modelBox.origin.x) * CGFloat(maskWidth) / modelBox.width
                let maskCoordY = (modelTapPoint.y - modelBox.origin.y) * CGFloat(maskHeight) / modelBox.height
                // --- With These Lines ---
                let clampedX = min(max(maskCoordX, 0), CGFloat(maskWidth - 1)) // Ensure maskWidth > 0 checked before
                let clampedY = min(max(maskCoordY, 0), CGFloat(maskHeight - 1)) // Ensure maskHeight > 0 checked before
                let xIdx = Int(floor(clampedX))
                let yIdx = Int(floor(clampedY))
                // --- End With ---

                let maskValue = maskData[yIdx][xIdx]

                if maskValue > 0.0001 { // Hit threshold
                    print("Hit detected on person \(person.id) at mask coord (\(xIdx), \(yIdx)), value \(maskValue)")

                    // Store the tap location *relative to the frame* for popover positioning
                    annotationPosition = location
                    selectedPersonID = person.id
                    newAnnotationText = person.annotation ?? ""
                    withAnimation(.easeInOut) { // Animate popover appearance
                         showAnnotationInput = true
                    }
                    return // Found hit
                }
            }
        }
        print("Long press at frame location \(location) did not hit any mask pixel above threshold.")
    }
}

// MARK: - Annotation Input Popover View (Keep as before)
struct AnnotationInputView: View {
    @Binding var annotationText: String
    let position: CGPoint // Now expects absolute screen position or position relative to parent
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Tag this person")
                .font(.headline)
                .foregroundColor(.white)

            TextField("Enter name...", text: $annotationText)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color.white.opacity(0.85)) // Slightly less transparent
                .cornerRadius(8)
                .foregroundColor(.black)

            HStack {
                Button("Cancel") { onCancel() }
                .buttonStyle(.bordered)
                .tint(.gray)

                Spacer()

                Button("Save") { onSave() }
                .buttonStyle(.borderedProminent)
                .disabled(annotationText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 8)
        .frame(maxWidth: 250)
        // Use the calculated position (relative to the container)
        .position(x: position.x, y: position.y)
        .transition(.scale(scale: 0.9).combined(with: .opacity)) // Animation
        .onTapGesture { /* Consume taps on popover background? Optional */ }
    }
}

// MARK: - Reusable Buttons

struct CircleButton: View {
    let icon: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 45, height: 45)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(.white)
                )
        }
    }
}

struct StoryButton: View {
    let title: String
    let image: String
    var isGreen = false

    var body: some View {
        HStack {
            Image(systemName: image)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isGreen ? Color.green.opacity(0.85) : Color.white.opacity(0.2))
        .foregroundColor(.white)
        .clipShape(Capsule())
    }
}
