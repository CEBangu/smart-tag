//
//  PostDetailView.swift
//  smart_tag
//
//  Created by Ciprian Bangu on 2025-04-03.
//
import SwiftUI

// --- Define frame constants (make accessible) ---
fileprivate let imageFrameWidth: CGFloat = 550
fileprivate let imageFrameHeight: CGFloat = 750
// --- End Constants ---

// Main view for displaying the posted image with interactive tags
struct PostDetailView: View {
    // Data passed from ContentView
    let image: UIImage
    // Ensure this includes maskImage if available from ContentView
    let taggedPeople: [DetectedPerson]

    @Environment(\.dismiss) var dismiss

    // State for tag popover
    @State private var showTagPopover = false
    @State private var popoverTagName: String? = nil
    // Store tap position relative to the IMAGE FRAME's coordinate space (0,0 top-left)
    @State private var popoverTargetPosition: CGPoint = .zero
    @State private var activeTaggedPerson: DetectedPerson? = nil

    // State for single pulse animation
    @State private var isPulsing: Bool = false

    // Mock data
    let username = "chippy_tv"
    let profileImageName = "person.crop.circle"
    let timeAgo = "Now"

    var body: some View {
        NavigationStack {
            // Use GeometryReader to get parent dimensions for positioning calculations
            GeometryReader { fullViewGeometry in
                // Main ZStack layers background, content, and UI overlays
                ZStack {
                    Color.black.ignoresSafeArea()

                    // --- Fixed-size Image Content Area ---
                    // Position this ZStack explicitly using .position()
                    ZStack {
                        // 1. Base Image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit() // Fit within the frame

                        // 2. Pulsing Masks
                        ForEach(taggedPeople) { person in
                            if person.annotation != nil {
                                Image(uiImage: person.maskImage)
                                    .resizable()
                                    .scaledToFill() // Match ContentView mask scaling
                                    .blendMode(.plusLighter) // Match ContentView blend mode
                                    .opacity(isPulsing ? 0.20 : 0.0)
                                    .animation(.easeInOut(duration: 0.7), value: isPulsing)
                                    .allowsHitTesting(false)
                            }
                        }

                        // 3. Tap Overlay
                        TapRegionOverlayView(
                            taggedPeople: taggedPeople,
                            imageSize: image.size,
                            displayFrameSize: CGSize(width: imageFrameWidth, height: imageFrameHeight),
                            onHit: { person, location in
                                if let annotation = person.annotation, !annotation.isEmpty {
                                    activeTaggedPerson = person
                                    popoverTagName = annotation
                                    // Location is relative to the TapRegionOverlayView's frame (which is 550x750)
                                    popoverTargetPosition = location
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        showTagPopover = true
                                    }
                                } else {
                                    withAnimation { showTagPopover = false }
                                }
                            },
                            onMiss: {
                                withAnimation { showTagPopover = false }
                            }
                        )
                    } // --- End Image/Pulse/Tap ZStack ---
                    .frame(width: imageFrameWidth, height: imageFrameHeight)
                    .clipped()
                    // --- EXPLICITLY POSITION THE FRAME ---
                    .position(
                        x: fullViewGeometry.size.width / 2,  // Center horizontally in parent
                        y: fullViewGeometry.size.height / 2 + (-30) // Center vertically + offset
                        // Note: Using screen center Y, not the 0.8 multiplier used before
                    )
                    // --- Removed separate .offset() ---


                    // --- Tag Popover Display (using absolute positioning) ---
                    if showTagPopover, let name = popoverTagName {
                        // Calculate the frame's top-left origin based on its explicit position
                        let frameOriginX = (fullViewGeometry.size.width / 2) - (imageFrameWidth / 2)
                        let frameOriginY = (fullViewGeometry.size.height / 2) + (-30) - (imageFrameHeight / 2) // Center Y + Offset - Half Height

                        // Calculate absolute position for popover relative to the main ZStack
                        let absolutePopoverX = frameOriginX + popoverTargetPosition.x
                        let absolutePopoverY = frameOriginY + popoverTargetPosition.y - 30 // Offset popover above tap

                        NavigationLink {
                            UserProfileView(username: name)
                        } label: {
                            TagPopoverView(tagName: name)
                        }
                        // Apply the absolute position
                        .position(x: absolutePopoverX, y: absolutePopoverY)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                        .zIndex(1) // Keep popover on top
                    }


                    // --- UI Overlay Layer (Header, Footer) ---
                    // This VStack should naturally align within the ZStack's bounds
                    VStack(spacing: 0) {
                         HeaderView(
                             profileImageName: profileImageName,
                             username: username,
                             timeAgo: timeAgo
                         ) { dismiss() }
                         Spacer() // Pushes footer down
                         FooterView()
                     }
                     // Ensure VStack doesn't contribute to unexpected width/shifting
                     .frame(maxWidth: .infinity) // Allow VStack to span width if needed by children
                    .padding(.bottom, 10)
                    .allowsHitTesting(true) // Allow interaction

                } // End main ZStack
                .statusBarHidden(true)
                .onAppear { // Single Pulse Logic
                    guard !isPulsing else { return }
                    isPulsing = false
                    withAnimation(.easeInOut(duration: 0.7)) { isPulsing = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeInOut(duration: 0.7)) { isPulsing = false }
                    }
                } // --- End .onAppear ---

            } // End GeometryReader
        } // End NavigationStack
    }

    // Removed calculatePopoverPosition helper function as calculation is inline
}


// MARK: - Header Subview (No Changes Needed)
struct HeaderView: View {
    let profileImageName: String
    let username: String
    let timeAgo: String
    let dismissAction: () -> Void
    @State private var progress: CGFloat = 0.7
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                Capsule().fill(.gray.opacity(0.5)).overlay(alignment: .leading) {
                        Capsule().fill(.white).frame(width: geo.size.width * progress) }
            }.frame(height: 3).padding(.top, 5)
            HStack(spacing: 10) {
                Image(systemName: profileImageName).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36).clipShape(Circle()).foregroundColor(.white)
                Text(username).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                Text(timeAgo).font(.system(size: 15)).foregroundColor(.white.opacity(0.7))
                Image(systemName: "star.fill").foregroundColor(.white).font(.system(size: 10))
                    .padding(5).background(Color.green).clipShape(RoundedRectangle(cornerRadius: 6))
                Spacer()
                Button { print("Ellipsis tapped") } label: { Image(systemName: "ellipsis").foregroundColor(.white).font(.system(size: 20)) }
                Button { dismissAction() } label: { Image(systemName: "xmark").foregroundColor(.white).font(.system(size: 20, weight: .bold)) }
                .padding(.leading, 5)
            }
        }.padding(.horizontal).padding(.top, 10)
    }
}

// MARK: - Footer Subview (No Changes Needed)
struct FooterView: View {
    @State private var messageText = ""
    var body: some View {
        HStack(spacing: 15) {
            HStack {
                if messageText.isEmpty { Text("Send message...").foregroundColor(.white.opacity(0.6)).padding(.leading, 15) }
                TextField("", text: $messageText).foregroundColor(.white).padding(.leading, messageText.isEmpty ? 0 : 15)
                Spacer()
            }.frame(height: 44).background(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
            Button { print("Heart tapped") } label: { Image(systemName: "heart").foregroundColor(.white).font(.system(size: 24)) }
        }.padding(.horizontal)
    }
}

// MARK: - Tag Popover View (No Changes Needed)
struct TagPopoverView: View {
    let tagName: String
    var body: some View {
        Text(tagName)
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.black.opacity(0.65).clipShape(RoundedRectangle(cornerRadius: 6)))
            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
    }
}


// MARK: - Tap Region Overlay (Should be correct for Fixed Frame / ScaledToFit)
struct TapRegionOverlayView: View {
    let taggedPeople: [DetectedPerson]
    let imageSize: CGSize
    let displayFrameSize: CGSize // e.g., 550x750
    let onHit: (DetectedPerson, CGPoint) -> Void
    let onMiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .contentShape(Rectangle())
                .simultaneousGesture(
                     DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            findTappedPerson(at: value.location, frameSize: geometry.size)
                        }
                )
        }
        .frame(width: displayFrameSize.width, height: displayFrameSize.height)
    }

    // --- Hit Testing Logic for ScaledToFit within Fixed Frame ---
    // (Logic remains the same as previous correct version)
    private func findTappedPerson(at location: CGPoint, frameSize: CGSize) {
        guard imageSize != .zero, frameSize != .zero else { onMiss(); return }
        // ... (Rest of the hit testing logic is unchanged) ...
        // 1. Determine image content rect within the fixed frame
        let frameAspect = frameSize.width / frameSize.height
        let imageAspect = imageSize.width / imageSize.height
        var imageRectInFrame: CGRect = .zero
        if frameAspect > imageAspect {
            let scaledWidth = imageSize.width * (frameSize.height / imageSize.height)
            imageRectInFrame = CGRect(x: (frameSize.width - scaledWidth) / 2.0, y: 0, width: scaledWidth, height: frameSize.height)
        } else {
            let scaledHeight = imageSize.height * (frameSize.width / imageSize.width)
            imageRectInFrame = CGRect(x: 0, y: (frameSize.height - scaledHeight) / 2.0, width: frameSize.width, height: scaledHeight)
        }
        // 2. Check tap within scaled image bounds
        guard imageRectInFrame.contains(location) else { onMiss(); return }
        // 3. Convert tap relative to image content
        let tapX_relative = location.x - imageRectInFrame.origin.x
        let tapY_relative = location.y - imageRectInFrame.origin.y
        // 4. Convert relative tap to original image coords
        let scaleToFit = min(imageRectInFrame.width / imageSize.width, imageRectInFrame.height / imageSize.height)
        guard scaleToFit > 0 else { onMiss(); return }
        let tapX_in_Image = tapX_relative / scaleToFit
        let tapY_in_Image = tapY_relative / scaleToFit
        // --- Check masks ---
        for person in taggedPeople.reversed() {
            let lbInfo = person.letterboxInfo
            let modelBox = person.modelInputBoundingBox
            let maskData = person.maskData
            let maskHeight = maskData.count
            let maskWidth = maskData.first?.count ?? 0
            guard maskWidth > 0, maskHeight > 0 else { continue }
            // 5. Original -> Model Coords
            let tapX_in_Model = tapX_in_Image * lbInfo.scale + lbInfo.xOffset
            let tapY_in_Model = tapY_in_Image * lbInfo.scale + lbInfo.yOffset
            let modelTapPoint = CGPoint(x: tapX_in_Model, y: tapY_in_Model)
            // Check BBox
            if modelBox.contains(modelTapPoint) {
                // 6. Model -> Mask Coords
                let maskCoordX = (modelTapPoint.x - modelBox.origin.x) * CGFloat(maskWidth) / modelBox.width
                let maskCoordY = (modelTapPoint.y - modelBox.origin.y) * CGFloat(maskHeight) / modelBox.height
                let clampedX = min(max(maskCoordX, 0), CGFloat(maskWidth - 1))
                let clampedY = min(max(maskCoordY, 0), CGFloat(maskHeight - 1))
                let xIdx = Int(floor(clampedX))
                let yIdx = Int(floor(clampedY))
                guard xIdx >= 0 && xIdx < maskWidth && yIdx >= 0 && yIdx < maskHeight else { continue }
                // Sample mask
                let maskValue = maskData[yIdx][xIdx]
                // Threshold check
                if maskValue > 0.00001 { // Keep low threshold
                    onHit(person, location) // Pass location relative to frame
                    return
                }
            }
        } // End loop
        onMiss() // No hit found
    }
}
