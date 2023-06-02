//
//  MultiTouchGestureRecognizer.swift
//  OnscreenController
//
//  Created by Grady Haynes on 4/5/23.
//  Copyright © 2023 Grady Haynes. All rights reserved.
//

#if canImport(UIKit)

import UIKit

class MultiTouchGestureRecognizer: UIGestureRecognizer {
    
    private var touches: Set<UITouch> = []
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        self.touches.formUnion(touches)
        updateState()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        updateState()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.touches.subtract(touches)
        updateState()
    }
    
    private func updateState() {
        // TODO: Are these sufficient? What are we missing out by not transitioning it through .started, etc?
        state = touches.isEmpty ? .ended : .changed
    }
}

#endif
