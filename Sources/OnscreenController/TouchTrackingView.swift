//
//  TouchTrackingView.swift
//  OnscreenController
//
//  Created by Grady Haynes on 4/5/23.
//  Copyright © 2023 Grady Haynes. All rights reserved.
//

#if canImport(UIKit)

import SwiftUI

struct TouchTrackingView: UIViewRepresentable {

    class Coordinator: NSObject {
        private let tappedHandler: ([CGPoint]) -> Void

        init(tappedHandler: @escaping ([CGPoint]) -> Void) {
            self.tappedHandler = tappedHandler
        }
        
        @objc func tapped(gesture: MultiTouchGestureRecognizer) {
            tappedHandler(touchLocations(for: gesture))
        }
        
        private func touchLocations(for gesture: MultiTouchGestureRecognizer) -> [CGPoint] {
            if gesture.state == .ended {
                return []
            } else {
                return (0..<gesture.numberOfTouches).map {
                    gesture.location(ofTouch: $0, in: gesture.view)
                }
            }
        }
    }

    var tappedHandler: ([CGPoint]) -> Void

    func makeUIView(context: UIViewRepresentableContext<TouchTrackingView>) -> TouchTrackingView.UIViewType {
        let gesture = MultiTouchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        let view = UIView(frame: .zero)
        view.addGestureRecognizer(gesture)
        return view
    }

    func makeCoordinator() -> TouchTrackingView.Coordinator {
        Coordinator(tappedHandler: tappedHandler)
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TouchTrackingView>) {
        
    }
}

#endif
