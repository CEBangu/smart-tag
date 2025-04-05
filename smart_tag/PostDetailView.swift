//
//  PostDetailView.swift
//  smart_tag
//
//  Created by Ciprian Bangu on 2025-04-03.
//
import SwiftUI

// Main view for displaying the posted image with interactive tags
struct PostDetailView: View {
    // Data passed from ContentView
    let image: UIImage
    let taggedPeople: [DetectedPerson] // Contains all necessary data for hit-testing

    // Environment variable to dismiss the view (e.g., via 'X' button)
    @Environment(\.dismiss) var dismiss

    // State for managing the custom tag popover
    @State private var showTagPopover = false
    @State private var popoverTagName: String? = nil
    @State private var popoverTargetPosition: CGPoint = .zero // Position relative to the overlay
    @State private var activeTaggedPerson: DetectedPerson? = nil // Store person for the popover's action

    // Mock data for UI elements (replace with real data later)
    let username = "chippy_tv" // Username for the story itself
    let profileImageName = "person.crop.circle" // Use system name or your asset name
    let timeAgo = "Now" // Or calculate dynamically

    var body: some View {
        // Wrap the entire view in a NavigationStack to enable navigation links
        // within this view, even when presented modally.
        NavigationStack {
            // Use GeometryReader to get the available size for positioning
            GeometryReader { fullViewGeometry in
                ZStack {
                    // Background Color
                    Color.black.ignoresSafeArea()

                    // --- Main Content Layer (Image + Tap Overlay) ---
                    // Use a ZStack to establish a coordinate space for the popover
                    ZStack {
                        // Display the image, filling the available space (cropping edges if needed)
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()

                        // The overlay responsible for detecting taps on tagged regions
                        TapRegionOverlayView(
                            taggedPeople: taggedPeople,
                            imageSize: image.size, // Pass original image size for calculations
                            onHit: { person, location in
                                // Action when a tagged person's mask IS tapped (HIT)
                                if let annotation = person.annotation, !annotation.isEmpty {
                                    activeTaggedPerson = person // Store the person for the popover's action
                                    popoverTagName = annotation
                                    popoverTargetPosition = location // Store tap location within overlay
                                    // Show popover with animation
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        showTagPopover = true
                                    }
                                } else {
                                    // Tapped a detected person with no annotation - hide any existing popover
                                    withAnimation {
                                        showTagPopover = false
                                    }
                                }
                            },
                            onMiss: {
                                // Action when the tap DOES NOT hit a tagged mask (MISS)
                                // Hide any visible popover
                                withAnimation {
                                    showTagPopover = false
                                }
                            }
                        )
                    }
                    // Make the ZStack containing the image and tap overlay fill the screen
                    .frame(width: fullViewGeometry.size.width, height: fullViewGeometry.size.height)
                    .clipped() // Clip the image content if scaledToFill goes beyond the frame

                    // --- Tag Popover Display (Modified for Navigation) ---
                    // Conditionally display the popover view if needed
                    if showTagPopover, let name = popoverTagName {
                        // Wrap the visual popover (TagPopoverView) in a NavigationLink
                        NavigationLink {
                            // Destination View: UserProfileView, passing the tapped tag name
                            UserProfileView(username: name)
                        } label: {
                            // Label for the NavigationLink: This is what the user sees and taps
                            TagPopoverView(tagName: name) // No action needed here now
                        }
                        // Keep positioning, transition, and zIndex modifiers on the NavigationLink
                        .position(x: popoverTargetPosition.x,
                                  y: popoverTargetPosition.y - 30) // Offset slightly above the tap
                        .transition(.scale(scale: 0.85).combined(with: .opacity)) // Add animation
                        .zIndex(1) // Ensure popover appears above other content in the ZStack
                    } // --- End if showTagPopover ---


                    // --- UI Overlay Layer (Header, Footer) ---
                    // Placed above the image/popover layer in the ZStack
                    VStack(spacing: 0) {
                        // Header containing profile info, progress, actions
                        HeaderView(
                            profileImageName: profileImageName,
                            username: username, // Username of the story poster
                            timeAgo: timeAgo
                        ) {
                            // Dismiss action for the 'X' button
                            dismiss()
                        }

                        Spacer() // Pushes Footer to the bottom

                        // Footer containing message input simulation, heart button
                        FooterView()

                    } // End VStack for UI Overlay
                    .padding(.bottom, 10) // Add some padding above home indicator area
                    // Ensure UI elements in header/footer are tappable
                    .allowsHitTesting(true)

                } // End main ZStack
                // Hide the system status bar for a cleaner story-like look
                .statusBarHidden(true)
                // No need for .navigationTitle here as it's a modal presentation style

            } // End GeometryReader
        } // End NavigationStack
    }
}

// MARK: - Header Subview (Progress Bar, Profile, Actions)
struct HeaderView: View {
    let profileImageName: String
    let username: String
    let timeAgo: String
    let dismissAction: () -> Void // Closure to dismiss the view

    // Simple state for progress simulation
    @State private var progress: CGFloat = 0.7 // Example progress value

    var body: some View {
        VStack(spacing: 8) {
            // Progress Bar (Simplified visual representation)
            GeometryReader { geo in
                Capsule()
                    .fill(.gray.opacity(0.5)) // Background track
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(.white) // Foreground progress
                            .frame(width: geo.size.width * progress) // Width based on progress
                    }
            }
            .frame(height: 3) // Height of the progress bar
            .padding(.top, 5) // Padding below potential status bar area

            // Profile Info and Action Buttons
            HStack(spacing: 10) {
                // Profile picture placeholder
                Image(systemName: profileImageName) // Use system name or load from asset
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .foregroundColor(.white) // Added in case system image is used

                // Username
                Text(username)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                // Time indicator
                Text(timeAgo)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))

                // Green Star icon (simplified)
                Image(systemName: "star.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 10))
                    .padding(5)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer() // Pushes action buttons to the right

                // Ellipsis Button
                Button {
                    print("Ellipsis tapped") // Placeholder action
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }

                // Close ('X') Button
                Button {
                    dismissAction() // Execute the dismiss closure passed in
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                }
                .padding(.leading, 5)

            } // End HStack
        } // End VStack for Header elements
        .padding(.horizontal) // Side padding for the header content
        .padding(.top, 10) // Padding below the progress bar
    }
}

// MARK: - Footer Subview (Message Bar Simulation, Heart)
struct FooterView: View {
    // State for the simulated message input
    @State private var messageText = ""

    var body: some View {
        HStack(spacing: 15) {
            // Message Input Field (Visual simulation)
            HStack {
                // Show placeholder text if TextField is empty
                if messageText.isEmpty {
                    Text("Send message...")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.leading, 15)
                }
                // Hidden TextField to allow actual input if needed later
                TextField("", text: $messageText)
                    .foregroundColor(.white)
                    .padding(.leading, messageText.isEmpty ? 0 : 15) // Adjust padding based on placeholder

                Spacer() // Allow placeholder/text to fill space
            }
            .frame(height: 44) // Standard height for input field
            .background(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1)) // Bordered capsule

            // Heart Button
            Button {
                print("Heart tapped") // Placeholder action
            } label: {
                Image(systemName: "heart")
                    .foregroundColor(.white)
                    .font(.system(size: 24)) // Size of the heart icon
            }
        }
        .padding(.horizontal) // Side padding for the footer content
    }
}

// MARK: - Tag Popover View (The visual appearance of the tappable tag)
struct TagPopoverView: View {
    let tagName: String
    // Removed onTapAction as NavigationLink handles the tap

    var body: some View {
        Text(tagName)
            .font(.system(size: 22, weight: .semibold)) // Font styling for the tag
            .foregroundColor(.white) // Text color
            .padding(.horizontal, 10) // Horizontal padding inside the background
            .padding(.vertical, 6)    // Vertical padding inside the background
            .background(
                // Semi-opaque black background clipped to a rounded rectangle
                Color.black.opacity(0.65)
                .clipShape(RoundedRectangle(cornerRadius: 6)) // Creates the box shape
            )
            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2) // Subtle shadow
            // No .onTapGesture needed here when used as NavigationLink label
    }
}


// MARK: - Tap Region Overlay (Handles hit testing on masks)
struct TapRegionOverlayView: View {
    let taggedPeople: [DetectedPerson] // Data needed for hit testing
    let imageSize: CGSize              // Original image dimensions
    let onHit: (DetectedPerson, CGPoint) -> Void // Callback on successful hit (passes person and location)
    let onMiss: () -> Void                     // Callback on miss

    var body: some View {
        // Use GeometryReader to understand the overlay's frame in its parent's coordinate space
        GeometryReader { geometry in
            // Transparent background that can receive gestures
            Color.clear
                .contentShape(Rectangle()) // Ensures the entire frame is tappable
                // Use DragGesture with zero minimum distance to reliably capture tap location
                .simultaneousGesture(
                     DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            // Perform hit test when the gesture ends (tap finishes)
                            findTappedPerson(at: value.location, overlaySize: geometry.size)
                        }
                )
        }
    }

    // --- Hit Testing Logic ---
    private func findTappedPerson(at location: CGPoint, overlaySize: CGSize) {
        // Ensure needed dimensions are valid
        guard imageSize != .zero, overlaySize != .zero else {
             print("DEBUG findTappedPerson: Invalid sizes (imageSize: \(imageSize), overlaySize: \(overlaySize))")
             onMiss() // Cannot perform test if sizes are zero
             return
        }

        // 1. Determine how the original image is scaled/positioned within the overlay
        //    using .scaledToFill() behavior.
        let overlayAspect = overlaySize.width / overlaySize.height
        let imageAspect = imageSize.width / imageSize.height
        var imageRectInOverlay: CGRect = .zero
        var scaleToFill: CGFloat = 1.0

        // Calculate the rectangle the image occupies within the overlay frame
        if imageAspect > overlayAspect { // Image wider than overlay frame
            scaleToFill = overlaySize.height / imageSize.height
            let scaledWidth = imageSize.width * scaleToFill
            imageRectInOverlay = CGRect(x: (overlaySize.width - scaledWidth) / 2.0, y: 0, width: scaledWidth, height: overlaySize.height)
        } else { // Image taller than or same aspect as overlay frame
            scaleToFill = overlaySize.width / imageSize.width
            let scaledHeight = imageSize.height * scaleToFill
            imageRectInOverlay = CGRect(x: 0, y: (overlaySize.height - scaledHeight) / 2.0, width: overlaySize.width, height: scaledHeight)
        }
        // print("DEBUG findTappedPerson: ImageRectInOverlay: \(imageRectInOverlay)")

        // 2. Check if tap location is within the bounds of the displayed image content
        guard imageRectInOverlay.contains(location) else {
            // print("DEBUG findTappedPerson: Tap \(location) outside ImageRectInOverlay \(imageRectInOverlay)")
            onMiss() // Tap is outside the visible image part
            return
        }

        // 3. Convert tap location to be relative to the image content's top-left corner
        let tapX_relative = location.x - imageRectInOverlay.origin.x
        let tapY_relative = location.y - imageRectInOverlay.origin.y
        // print("DEBUG findTappedPerson: Tap Relative: (\(tapX_relative), \(tapY_relative))")


        // 4. Convert relative tap location to coordinates in the original, unscaled image
        guard scaleToFill > 0 else { print("DEBUG findTappedPerson: Invalid scaleToFill"); onMiss(); return }
        let tapX_in_Image = tapX_relative / scaleToFill
        let tapY_in_Image = tapY_relative / scaleToFill
        // print("DEBUG findTappedPerson: Tap in Original Coords: (\(tapX_in_Image), \(tapY_in_Image))")


        // --- Iterate through tagged people to check for mask hit ---
        for person in taggedPeople.reversed() { // Check visually "topmost" first
            // Ensure all necessary info for this person is available
            let lbInfo = person.letterboxInfo
            let modelBox = person.modelInputBoundingBox
            let maskData = person.maskData
            let maskHeight = maskData.count
            let maskWidth = maskData.first?.count ?? 0
            guard maskWidth > 0, maskHeight > 0 else { continue } // Skip if mask data invalid

            // 5. Convert original image coordinates to the model's input coordinate space (e.g., 640x640)
            let tapX_in_Model = tapX_in_Image * lbInfo.scale + lbInfo.xOffset
            let tapY_in_Model = tapY_in_Image * lbInfo.scale + lbInfo.yOffset
            let modelTapPoint = CGPoint(x: tapX_in_Model, y: tapY_in_Model)
            // print("DEBUG findTappedPerson: Checking Person \(person.id), Model Tap: \(modelTapPoint), Model BBox: \(modelBox)")


            // Optimization: Check if tap is within the person's bounding box first
            if modelBox.contains(modelTapPoint) {
                // print("DEBUG findTappedPerson: Tap inside BBox for Person \(person.id)")
                // 6. Convert model tap coordinates to the mask's own coordinate system (e.g., 0-160)
                let maskCoordX = (modelTapPoint.x - modelBox.origin.x) * CGFloat(maskWidth) / modelBox.width
                let maskCoordY = (modelTapPoint.y - modelBox.origin.y) * CGFloat(maskHeight) / modelBox.height

                // Clamp coordinates to be within the valid range of mask indices
                let clampedX = min(max(maskCoordX, 0), CGFloat(maskWidth - 1))
                let clampedY = min(max(maskCoordY, 0), CGFloat(maskHeight - 1))

                // Get integer indices for accessing the maskData array
                let xIdx = Int(floor(clampedX))
                let yIdx = Int(floor(clampedY))

                // Double-check bounds just in case
                guard xIdx >= 0 && xIdx < maskWidth && yIdx >= 0 && yIdx < maskHeight else {
                    // print("DEBUG findTappedPerson: Indices out of bounds (\(xIdx), \(yIdx)) for mask size (\(maskWidth), \(maskHeight))")
                    continue
                }

                // Sample the mask data at the calculated indices
                let maskValue = maskData[yIdx][xIdx]
                // print("DEBUG findTappedPerson: Sampled Mask Value at [\(yIdx)][\(xIdx)]: \(maskValue)")


                // Check if the sampled mask value is above the threshold for a hit
                // (Using the lower threshold as decided earlier)
                if maskValue > 0.00001 { // Keep using the lower threshold that worked
                    print("HIT on person \(person.id), Annotation: \(person.annotation ?? "None")")
                    // Call the onHit callback, passing the person and the tap location (relative to overlay)
                    onHit(person, location)
                    return // Exit function as soon as a hit is found
                }
            } else {
                 // print("DEBUG findTappedPerson: Tap outside BBox for Person \(person.id)")
            }
        } // End loop through taggedPeople
        onMiss() // Call the onMiss callback
    }
}
