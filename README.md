# CZImageEditor

An image editor that can apply preset filters passed to it and customized editings to a binded image. Customized editings include rotation, zooming, cropping, brightness, contrast, saturation, warmth, and sharpen.

This editor uses a struct called `ImageEditorParameters` to keep track of the changes made to the image, so users get chance to revert the changes them made. You should create and keep this struct along with the `CZImageEditor` when you use this editor. Check the **Usage** section for details.

## Features

## Preview

   Preset Filters     |         Rotation and Crop      |       Custom Editing       |
:-------------------------:|:-------------------------:|:-------------------------:
![preview1](./previews/preview1.gif)  |  ![preview2](./previews/preview2.gif)  |  ![preview3](./previews/preview3.gif)




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

Add a package by selecting `File` → `Add Packages…` in Xcode’s menu bar.

Search for the CZImageEditor using the repo's URL:
```console
https://github.com/firebase/firebase-ios-sdk.git
```
