//
//  Extension.swift
//  TestingForPhotoEditor
//
//  Created by Kaiyi Zhao on 8/1/22.
//

import SwiftUI

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

extension CGPoint {
    static func -(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.x - rhs.x, height: lhs.y - rhs.y)
    }
    static func +(lhs: Self, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }
    static func -(lhs: Self, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
    }
    static func *(lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    static func /(lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}

extension CGSize {
    // the center point of an area that is our size
    var center: CGPoint {
        CGPoint(x: width/2, y: height/2)
    }
    static func +(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    static func -(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    static func *(lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    static func /(lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width/rhs, height: lhs.height/rhs)
    }
    
    func maxRatio(with targetSize: CGSize) -> CGFloat {
        max(self.width / targetSize.width, self.height / targetSize.height)
    }
    
    func minRatio(with targetSize: CGSize) -> CGFloat {
        min(self.width / targetSize.width, self.height / targetSize.height)
    }
    
    func rotatedVector(radians: CGFloat, center: CGSize = .zero) -> CGSize {
        let newX = (self.width - center.width) * cos(radians) - (self.height - center.height) * sin(radians) + center.width
        let newY = (self.width - center.width) * sin(radians) + (self.height - center.height) * cos(radians) + center.height
        
        return CGSize(width: newX, height: newY)
    }
    
    func reverseWidth() -> CGSize {
        CGSize(width: -self.width, height: self.height)
    }
    func reverseHeight() -> CGSize {
        CGSize(width: self.width, height: -self.height)
    }
    func reverseWidthHeight() -> CGSize {
        CGSize(width: -self.width, height: -self.height)
    }
}

extension Double {
    func angleDegrees() -> Double {
        let angle = self.truncatingRemainder(dividingBy: Double.pi * 2)
        return angle * 180 / Double.pi
    }
}

extension UIColor {
    func uiImage(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
