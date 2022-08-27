//
//  RegisterCustomFilters.swift
//  TestPhotoEditor
//
//  Created by Kaiyi Zhao on 8/20/22.
//

import CoreImage

class CustomFiltersVendor: NSObject, CIFilterConstructor {
    static func registerFilters() {
        CIFilter.registerName("CZOriginal", constructor: CustomFiltersVendor(),
                              classAttributes: [kCIAttributeFilterCategories: ["CustomFilters"]])
        CIFilter.registerName("CZCrystal", constructor: CustomFiltersVendor(),
                              classAttributes: [kCIAttributeFilterCategories: ["CustomFilters"]])
        CIFilter.registerName("CZVivid", constructor: CustomFiltersVendor(),
                              classAttributes: [kCIAttributeFilterCategories: ["CustomFilters"]])
        CIFilter.registerName("CZAir", constructor: CustomFiltersVendor(),
                              classAttributes: [kCIAttributeFilterCategories: ["CustomFilters"]])
    }

    func filter(withName name: String) -> CIFilter? {
        switch name {
        case "CZOriginal": return CZOriginalFilter()
        case "CZCrystal": return CZCrystalFilter()
        case "CZVivid": return CZVividFilter()
        case "CZAir": return CZAirFilter()
        default: return nil
        }
    }
}


