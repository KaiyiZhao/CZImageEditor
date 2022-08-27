# CZImageEditor

An editor that can apply preset filters passed to it and customized editings to a binded image. Customized editings include rotation, zooming, cropping, brightness, contrast, saturation, warmth, and sharpen.

## Features

This editor uses a struct called ImageEditorParameters to keep track of the changes made to the image, so users get chance to revert the changes them made. You should create and keep this struct along with the CZImageEditor when you use this editor.

## Preview

## Usage
### Parameters
### Example
The following example shows a typcial scenario of how this editor should be used in your code.

```swift
   struct ContentView: View {
       @State private var image = UIImage(named: "testImage")!
       @State private var showImageEditor = false
       @State private var savedImageEditorParameters = ImageEditorParameters()

       var body: some View {
           VStack {
               Image(uiImage: image)
                   .resizable()
                   .scaledToFit()
                   .onTapGesture {
                       showImageEditor = true
                   }
           }
           .frame(width: 200, height: 300)
           .fullScreenCover(isPresented: $showImageEditor) {
               CZImageEditor(image: $image, parameters: $savedImageEditorParameters)
           }
       }
   }
```
## Installation