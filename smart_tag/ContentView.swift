//
//  smart_tagApp.swift
//  smart_tag
//
//  Created by Ciprian Bangu on 2025-03-27.
//

// TODO: transparent pop-up text box; better clicking options + shouldn't be able to long press anywhere on the screen; save co-ordinates to populate next view


import SwiftUI
import PhotosUI

struct MaskTag: Identifiable {
    let id = UUID()
    let image: UIImage
    var meta_data: Dictionary<String, Any>? = nil
}

struct ContentView: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var caption = ""

    @State private var tags: [MaskTag] = []
    @State private var selectedTagID: UUID? = nil
    @State private var newAnnotationText: String = ""
    @State private var showAnnotationInput = false

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .overlay(
                ZStack {
                    if let image = selectedImage {
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 550, height: 750)
                                .cornerRadius(120)
                                .clipped()
                                .offset(y: -30)

                            ForEach(tags) { tag in
                                Image(uiImage: tag.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 550, height: 750)
                                    .offset(y: -30)
                                    .blendMode(.plusLighter)
                                    .opacity(0.35)
                                    .allowsHitTesting(true)
                                    .onLongPressGesture {
                                        selectedTagID = tag.id
                                        newAnnotationText = tag.annotation ?? ""
                                        showAnnotationInput = true
                                    }
                            }
                        }
                    } else {
                        Button(action: {
                            showPhotoPicker = true
                        }) {
                            VStack {
                                Image(systemName: "plus.circle")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white)
                                Text("Add Photo")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                    }
                }
            )
            .overlay(
                VStack {
                    HStack(spacing: 20) {
                        CircleButton(icon: "xmark") {
                            selectedImage = nil
                            tags = []
                            selectedTagID = nil
                        }
                        Spacer()
                        CircleButton(icon: "textformat")
                        CircleButton(icon: "face.smiling")
                        CircleButton(icon: "music.note")
                        CircleButton(icon: "sparkles")
                        CircleButton(icon: "ellipsis")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    Spacer()

                    VStack(spacing: 12) {
                        ZStack(alignment: .leading) {
                            if caption.isEmpty {
                                Text("Add a caption...")
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(.leading, 10)
                            }
                            TextField("", text: $caption)
                                .foregroundColor(.white)
                                .padding()
                        }
                        .background(Color.clear)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            StoryButton(title: "Your story", image: "person.crop.circle")
                            StoryButton(title: "Close Friends", image: "star.circle.fill", isGreen: true)

                            Button(action: {
                                print("Send tapped")
                            }) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.black)
                                    )
                            }
                        }
                        .padding(.bottom, 10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage

                        guard let resized = letterboxResize(image: uiImage),
                              let pixelBuffer = pixelBuffer(from: resized.image, size: CGSize(width: 640, height: 640)),
                              let model = loadModel()
                        else {
                            print("Preprocessing failed")
                            return
                        }

                        let masks = await runSegmentationModel(model: model, pixelBuffer: pixelBuffer)
                        tags = masks.map { MaskTag(image: $0) }
                    }
                }
            }
            .fullScreenCover(isPresented: $showAnnotationInput) {
                TransparentSheet {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()

                        VStack(spacing: 20) {
                            Text("Tag this person")
                                .font(.headline)
                                .foregroundColor(.white)

                            TextField("Add a label...", text: $newAnnotationText)
                                .textFieldStyle(.roundedBorder)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)

                            Button("Save") {
                                if let id = selectedTagID,
                                   let i = tags.firstIndex(where: { $0.id == id }) {
                                    tags[i].annotation = newAnnotationText
                                }
                                showAnnotationInput = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(40)
                    }
                }
            }
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
