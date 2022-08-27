//
//  EditOption.swift
//  TestingForPhotoEditor
//
//  Created by Kaiyi Zhao on 8/6/22.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

enum EditOption: String, CaseIterable {
    case rotation = "Adjust"
    case brightness = "Brightness"
    case contrast = "Contrast"
    case saturation = "Saturation"
    case warmth = "Warmth"
    case sharpen = "Sharpen"
    
    var minValue: Double {
        switch self {
        case .rotation: return -180.0 * 100
        case .brightness: return -10
        case .contrast: return 50
        case .saturation: return -100
        case .warmth: return (6500 - 4500) * 100
        case .sharpen: return (0.4 - 1.0) * 100
        }
    }
    
    var maxValue: Double {
        switch self {
        case .rotation: return 180.0 * 100
        case .brightness: return 10
        case .contrast: return 150
        case .saturation: return 300.0
        case .warmth: return (6500 + 4500) * 100
        case .sharpen: return (0.4 + 1.0) * 100
        }
    }
    
    func calculatedValue(percent: Double) -> Double {
        (percent * (self.maxValue - self.minValue) + self.minValue)/100
    }
}
