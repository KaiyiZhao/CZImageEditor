//
//  FilteredImage.swift
//  TestingForPhotoEditor
//
//  Created by Kaiyi Zhao on 8/1/22.
//

import Foundation
import CoreImage
import UIKit

struct FilteredImage: Identifiable {
    let id: Int // filter order to display
    let image: UIImage
    let filter: CIFilter
    let name: String
}
