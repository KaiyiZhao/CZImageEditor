//
//  CZAirFilter.swift
//  TestPhotoEditor
//
//  Created by Kaiyi Zhao on 8/21/22.
//

import CoreImage
import CoreImage.CIFilterBuiltins

public class CZAirFilter: CIFilter {
    @objc dynamic var inputImage: CIImage?
    
    public override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "Air",
        
            kCIInputImageKey: [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage]
        ]
    }
    
    public override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }
        let finalImage = inputImage
            .applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: 0.25]) // default: 0.0
            .applyingFilter("CITemperatureAndTint", parameters: ["inputNeutral": CIVector(x: 6000, y: 0)]) // default: 6500
            .applyingFilter("CIHighlightShadowAdjust",
                            parameters: ["inputHighlightAmount": 1.05]) // default: 1.0
//                                         "inputShadowAmount": 0.05]) // default: 0.0
            .applyingFilter("CIColorControls",
                            parameters: [kCIInputContrastKey: 1.05, // default: 1.0
                                       kCIInputSaturationKey: 1.05, // default: 1.0
                                       kCIInputBrightnessKey: 0.01]) // default: 0.0
            .applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: 0.1]) // default: 0.4
        
        return finalImage
    }
}
