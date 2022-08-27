//
//  CZOriginalFilter.swift
//  TestPhotoEditor
//
//  Created by Kaiyi Zhao on 8/20/22.
//

import CoreImage
import CoreImage.CIFilterBuiltins

public class CZOriginalFilter: CIFilter {
    @objc dynamic var inputImage: CIImage?
    
    public override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "Normal",
        
            kCIInputImageKey: [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage]
        ]
    }
    
    public override var outputImage: CIImage? {
        return inputImage
    }
}
