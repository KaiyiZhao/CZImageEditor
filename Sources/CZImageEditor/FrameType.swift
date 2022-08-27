//
//  FrameType.swift
//  TestingForPhotoEditor
//
//  Created by Kaiyi Zhao on 8/7/22.
//

import SwiftUI

public enum FrameType {
    case origin
    case fourByThree
    case square
    case threeByFour
    case circle
    
    func frameSize(imageSize: CGSize, campusSize: CGSize) -> CGSize {
        switch self {
        case .origin:
            let imageCampusRatio = imageSize.maxRatio(with: campusSize)
            return imageSize / imageCampusRatio * 0.9
        case .fourByThree:
            let frameWidth = campusSize.width * 0.9
            return CGSize(width: frameWidth, height: frameWidth/4*3)
        case .square:
            let minLength = min(campusSize.width, campusSize.height) * 0.9
            return CGSize(width: minLength, height: minLength)
        case .threeByFour:
            let frameHeight = campusSize.height * 0.9
            return CGSize(width: frameHeight/4*3, height: frameHeight)
        case .circle:
            let minLength = min(campusSize.width, campusSize.height) * 0.8
            return CGSize(width: minLength, height: minLength)
        }
    }
}
