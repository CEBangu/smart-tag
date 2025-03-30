//
//  TransparentSheet.swift
//  smart_tag
//
//  Created by Ciprian Bangu on 2025-03-30.
//

import Foundation
import SwiftUI

struct TransparentSheet<Content: View>: UIViewControllerRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.modalPresentationStyle = .overFullScreen
        return host
    }

    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
        uiViewController.rootView = content
    }
}
