//
//  TextButton.swift
//  Cooking Zeal
//
//  Created by Kaiyi Zhao on 7/6/22.
//

import SwiftUI

struct TextButton: View {
    let text: String
    let color: Color
    let localizationPrefix: String
    let action: () -> Void
    
    init(text: String, color: Color, localizationPrefix: String, action: @escaping () -> Void) {
        self.text = text
        self.color = color
        self.localizationPrefix = localizationPrefix
        self.action = action
    }
    
    var body: some View {
        Button (action: action) {
            HStack(spacing: 0) {
                Text(LocalizedStringKey(localizationPrefix + text))
                    .font(Font.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(color)
            }
        }
        .frame(height: 24)
    }
}

struct TextButton_Previews: PreviewProvider {
    static var previews: some View {
        TextButton(text: "Text Button", color: .accentColor, localizationPrefix: "IE_") {
            
        }
    }
}
