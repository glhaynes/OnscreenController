//
//  OnscreenController.swift
//  OnscreenController
//
//  Created by Grady Haynes on 2/8/23.
//  Copyright © 2023 Grady Haynes. All rights reserved.
//

#if canImport(UIKit)

import SwiftUI
import Algorithms

public struct OnscreenController: View {
    
    private enum Button: CaseIterable {
        case up, down, left, right, select, start, b, a
    }
        
    private enum Region: Hashable, CaseIterable {
        case upLeft, up, upRight,
             left, center, right,
             downLeft, down, downRight
        case select, start
        case b, a
    }

    private struct RegionFramesKey: PreferenceKey {
        static var defaultValue: [Region: Anchor<CGRect>] = [:]
        static func reduce(value: inout [Region: Anchor<CGRect>], nextValue: () -> [Region: Anchor<CGRect>]) {
            value.merge(nextValue(), uniquingKeysWith: { _, new in new })
        }
    }
    
    private static let regionToButtons: [Region: [Button]] = [
        // D-pad top row:
        .upLeft: [.up, .left], .up: [.up], .upRight: [.up, .right],
        // D-pad middle row:
        .left: [.left], .center: [], .right: [.right],
        // D-pad bottom row:
        .downLeft: [.down, .left], .down: [.down], .downRight: [.down, .right],
        // Select / Start:
        .select: [.select], .start: [.start],
        // Action buttons:
        .b: [.b], .a: [.a]
    ]
    
    @State private var touchLocations: [CGPoint] = []
    @State private var regionFrames: [(Region, CGRect)] = []
    
    private let handlers: [Button: (Bool) -> ()]
    
    public init(up: @escaping (Bool) -> (),
                down: @escaping (Bool) -> (),
                left: @escaping (Bool) -> (),
                right: @escaping (Bool) -> (),
                select: @escaping (Bool) -> (),
                start: @escaping (Bool) -> (),
                b: @escaping (Bool) -> (),
                a: @escaping (Bool) -> ()
    ) {
        self.handlers = [
            .up: up,
            .down: down,
            .left: left,
            .right: right,
            .select: select,
            .start: start,
            .b: b,
            .a: a
        ]
    }

    // MARK: Views
    
    public var body: some View {
        GeometryReader { proxy in
            VStack {
                Spacer()
                    .frame(maxHeight: .infinity)
                
                mainContent(width: proxy.size.width)
            }
            .onPreferenceChange(RegionFramesKey.self) { regionFrames in
                self.regionFrames = translatedRegionFrames(for: regionFrames, using: proxy)
            }
        }
        .overlay {
            TouchTrackingView { touchLocations = $0 }
        }
        .onChange(of: touchLocations) {
            touchLocationsChanged(to: $0)
        }
        .ignoresSafeArea()
    }
            
    private var selectAndStart: some View {
        VStack(spacing: 20) {
            Capsule()
                .metaButtonStyle(title: "Select")
                .anchorPreference(key: RegionFramesKey.self, value: .bounds) { [.select: $0] }

            Capsule()
                .metaButtonStyle(title: "Start")
                .anchorPreference(key: RegionFramesKey.self, value: .bounds) { [.start: $0] }
        }
    }

    private var actionButtons: some View {
        HStack {
            Circle()
                .actionButtonStyle(title: "B")
                .anchorPreference(key: RegionFramesKey.self, value: .bounds) { [.b: $0] }

            Circle()
                .actionButtonStyle(title: "A")
                .anchorPreference(key: RegionFramesKey.self, value: .bounds) { [.a: $0] }
        }
    }
    
    private func mainContent(width w: CGFloat) -> some View {
        HStack(spacing: 5) {
            Spacer()
                .frame(width: 0)
            
            DpadShape()
                .stroke(.black, lineWidth: 12)
                .overlay {
                    DpadShape()
                        .fill(.gray)
                }
                .overlay {
                    Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                        GridRow {
                            dPadTouchRegion(.upLeft)
                            dPadTouchRegion(.up)
                            dPadTouchRegion(.upRight)
                        }
                        GridRow {
                            dPadTouchRegion(.left)
                            dPadTouchRegion(.center)
                            dPadTouchRegion(.right)
                        }
                        GridRow {
                            dPadTouchRegion(.downLeft)
                            dPadTouchRegion(.down)
                            dPadTouchRegion(.downRight)
                        }
                    }
                    .padding(-10)  // Extend the touch areas a little past the shown dpad
                }
                .frame(width: w * 0.3)
                .aspectRatio(1, contentMode: .fit)
                .padding(10)
                .layoutPriority(2)
            
            Spacer()
                .layoutPriority(1)
            
            selectAndStart
                .frame(width: w * 0.15)
            
            Spacer()
                .layoutPriority(1)
            
            actionButtons
                .frame(minWidth: w * 0.35)
            
            Spacer()
                .frame(width: 0)
        }
    }
    
    // MARK: Functions
    
    private func dPadTouchRegion(_ region: Region) -> some View {
        Color.clear
            .anchorPreference(key: RegionFramesKey.self, value: .bounds) { [region: $0] }
    }

    private func translatedRegionFrames(for regionFrames: [Region: Anchor<CGRect>],
                                        using proxy: GeometryProxy
    ) -> [(Region, CGRect)] {
        return regionFrames.map { region, anchor in
            (region, proxy[anchor])
        }
    }
        
    private func touchLocationsChanged(to touches: [CGPoint]) {
        let touchedRegions = touches.compactMap { touchPoint in
            regionFrames.first(where: { $0.1.contains(touchPoint) })?.0
        }
        
        let turnOnButtons = Set(touchedRegions.compactMap { region in
            Self.regionToButtons[region]
        }.flatMap { $0 })
        
        let turnOffButtons = Set(Button.allCases).subtracting(turnOnButtons)
            
        let allButtonStates = chain(
            turnOnButtons.map { ($0, true) },
            turnOffButtons.map { ($0, false) }
        )
        
        for (button, state) in allButtonStates {
            handlers[button]?(state)
        }
    }
}

// MARK: - Styling Extensions

extension Capsule {
    func metaButtonStyle(title: String = "") -> some View {
        self
            .stroke(.black, lineWidth: 0.5)
            .background(Capsule().fill(.gray))
            .aspectRatio(3, contentMode: .fit)
            .overlay {
                Text(title)
                    .font(.system(.caption, design: .rounded))
            }
    }
}

extension Circle {
    func actionButtonStyle(title: String = "") -> some View {
        self
            .stroke(.black)
            .background(Circle().fill(Color.accentColor))
            .overlay {
                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .opacity(0.8)
            }
    }
}

// MARK: - Previews

struct OnscreenController_Previews: PreviewProvider {
    static var previews: some View {
        OnscreenController(up: { _ in },
                           down: { _ in },
                           left: { _ in },
                           right: { _ in },
                           select: { _ in },
                           start: { _ in },
                           b: { _ in },
                           a: { _ in })
            .previewInterfaceOrientation(.landscapeLeft)
    }
}

#endif
