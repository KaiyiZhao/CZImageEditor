//
//  BoundsPreferenceKey.swift
//  TestingForPhotoEditor
//
//  Created by Kaiyi Zhao on 8/3/22.
//

import SwiftUI


struct BoundsPreferenceKey: PreferenceKey {
    typealias Value = CGRect

    static var defaultValue: Value = .zero

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

extension View {
    func getViewCoordinates (in space: CoordinateSpace) -> some View {
        self.background {
            GeometryReader { geo in
                Color.clear
                    .preference(key: BoundsPreferenceKey.self, value: geo.frame(in: space))
            }
        }
    }
    
    func doWithViewCoordinates(in space: CoordinateSpace, _ action: @escaping (CGRect) -> Void) -> some View {
        self
            .getViewCoordinates(in: space)
            .onPreferenceChange(BoundsPreferenceKey.self, perform: action)
    }
}
