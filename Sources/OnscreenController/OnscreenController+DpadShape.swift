//
//  OnscreenController+Shapes.swift
//  OnscreenController
//
//  Created by Grady Haynes on 2/9/23.
//  Copyright © 2023 Grady Haynes. All rights reserved.
//

#if canImport(UIKit)

import SwiftUI

extension OnscreenController {
    
    struct DpadShape: Shape {
        
        private enum LineDrawer {
            static func lines(inner: CGFloat, protrudance: CGFloat) -> [CGPoint] {
                transforms(inner: inner, protrudance: protrudance).flatMap { transform in
                    points(inner: inner, protrudance: protrudance).map { point in
                        point.applying(transform)
                    }
                }
            }
            
            private static func transforms(inner: CGFloat, protrudance: CGFloat) -> [CGAffineTransform] {
                [
                    .identity,
                    .init(translationX: inner, y: 0).rotated(by: .pi / 2),
                    .init(translationX: inner, y: inner).rotated(by: .pi),
                    .init(translationX: 0, y: inner).rotated(by: .pi * 3 / 2)
                ]
            }
                    
            private static func points(inner: CGFloat, protrudance: CGFloat) -> [CGPoint] {
                [
                    // Go up, right, back down
                    .init(x: 0, y: -protrudance),
                    .init(x: inner, y: -protrudance),
                    .init(x: inner, y: 0)
                ]
            }
        }
        
        func path(in rect: CGRect) -> Path {
            //let lineWidth = 16.0 // TODO: Make this automatic (this looks good on landscape iPhone)
            let lineWidth = 12.0  // Looks good on portrait iPhone
            return buildPath(in: rect, lineWidth: lineWidth)
        }
                
        private func buildPath(in rect: CGRect, lineWidth: CGFloat) -> Path {
            Path { path in
                let minSide = min(rect.width, rect.height)
                
                // Draw the lines
                //   `inner` is the "inner square", the neutral part of the dpad
                //   `protrudance` is how far each bar protrudes
                // TODO: Consider improving these names
                path.addLines(LineDrawer.lines(inner: minSide / 3,
                                               protrudance: minSide / 3 - lineWidth / 2))
                path.closeSubpath()
                
                // Center ourselves
                path = path.applying(.init(translationX: rect.midX - path.boundingRect.midX,
                                           y: rect.midY - path.boundingRect.midY))
                
                // Add an inner divot
                path.addEllipse(in: .init(origin: .init(x: rect.midX - minSide / 8, y: rect.midY - minSide / 8),
                                          size: CGSize(width: minSide / 4, height: minSide / 4)))
            }
        }
    }
}

#endif
