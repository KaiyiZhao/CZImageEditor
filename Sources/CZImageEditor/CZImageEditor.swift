//
//  CZImageEditor.swift
//  TestPhotoEditor
//
//  Created by Kaiyi Zhao on 8/18/22.
//

import SwiftUI

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI


/// An editor that can apply preset filters and customized editings to a binded image. Customized editings include rotation, zooming, cropping, brightness, contrast, saturation, warmth, and sharpen.
///
/// This editor uses a struct called ImageEditorParameters to keep track of the changes made to the image, so users get chance to revert the changes them made. You should create and keep this struct along with the CZImageEditor when you use this editor.
///
/// The following example shows a typcial scenario of how this editor should be used in your code.
///   ```
///   struct ContentView: View {
///       @State private var image = UIImage(named: "testImage")!
///       @State private var showImageEditor = false
///       @State private var savedImageEditorParameters = ImageEditorParameters()
///
///       var body: some View {
///           VStack {
///               Image(uiImage: image)
///                   .resizable()
///                   .scaledToFit()
///                   .onTapGesture {
///                       showImageEditor = true
///                   }
///           }
///           .frame(width: 200, height: 300)
///           .fullScreenCover(isPresented: $showImageEditor) {
///               CZImageEditor(image: $image, parameters: $savedImageEditorParameters)
///           }
///       }
///   }
///   ```
public struct CZImageEditor: View {
    @Binding var image: UIImage
    @Binding var parameters: ImageEditorParameters
    let frame: FrameType
    let filters: [CIFilter]
    let filterNameFont: Font
    let thumbnailMaxSize: CGFloat
    let localizationPrefix: String
    let actionWhenConfirm: (() -> Void)?
    
    // MARK: - init
    
    /// Only two required parameters are image and parameters. All other parameters have default values
    /// - Parameters:
    ///   - image: A binding to the image about to be edited.
    ///   - parameters: A binding to a group of parameters that contains the original image and all possible changes have been made to the image.
    ///   - frame: What frame shape you want to use. By default, it is the same shape of editing. You can also choose 4 by 3, square, 3 by 4, and circle.
    ///   - filters: The preset filters that can be chosen by user to apply to the image.
    ///   - filterNameFont: Text font applies to the preset filter name
    ///   - thumbnailMaxSize: The maximium length of the thumbnail of the image used during editing.
    ///   - localizationPrefix: A prefix string that attached to all text shown on the screen.
    ///   - actionWhenConfirm: An optional clousure that excutes when user confirm the changes to the image.
    public init(image: Binding<UIImage>,
         parameters: Binding<ImageEditorParameters>,
         frame: FrameType = .origin,
         filters: [CIFilter] = [
            CZOriginalFilter(),
            CZCrystalFilter(),
            CZVividFilter(),
            CZAirFilter()],
         filterNameFont: Font = .caption2,
         thumbnailMaxSize: CGFloat = 1600,
         localizationPrefix: String = "",
         actionWhenConfirm: (() -> Void)? = nil) {
        
        // register custom filters
        CustomFiltersVendor.registerFilters()
        
        self._image = image
        self._parameters = parameters
        self.frame = frame
        self.filters = filters
        self.filterNameFont = filterNameFont
        self.thumbnailMaxSize = thumbnailMaxSize
        self.localizationPrefix = localizationPrefix
        self.actionWhenConfirm = actionWhenConfirm
    }
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = CZImageEditorViewModel()
    
    // option selecting
    @State private var editType: EditType = .filter
    @State private var selectedEditOption: EditOption? = nil
    
    // filter option editing
    @State private var editingValue: Double = 0
    @State private var savedEditingValue: Double = 0
    
    // layout
    @State private var campusRect: CGRect = .zero
    
    @GestureState private var gesturePanOffset: CGSize = .zero
    @State private var savedEditPanOffset: CGSize = .zero
    
    @GestureState private var gestureZoomScale: CGFloat = 1
    @State private var savedEditZoomScale: CGFloat = 1
    
    // show original image to compare
    @State private var showOriginalImage = false
    
    public var body: some View {
        NavigationView {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    campus
                    
                    middlePanel
                    
                    bottomPanel(geo: geo)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        TextButton(text: "Cancel", color: .white, localizationPrefix: localizationPrefix) {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        TextButton(text: "Compare", color: .white, localizationPrefix: localizationPrefix) {
                        }
                        .opacity(changesWereMade ? 1 : 0)
                        .pressAction {
                            showOriginalImage = true
                        } onRelease: {
                            showOriginalImage = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        toolbarRightButton
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .task {
            await vm.initializeVM(fullImage: parameters.fullOriginalImage ?? image,
                                  parameters: parameters,
                                  filters: filters,
                                  thumbnailMaxSize: thumbnailMaxSize)
        }
    }
}

// MARK: - Preview
struct ImageEditor_Previews: PreviewProvider {
    static var previews: some View {
        CZImageEditor(image: Binding<UIImage>.constant(UIColor.gray.uiImage(CGSize(width: 200, height: 200))), parameters: .constant(.init()), frame: .origin, actionWhenConfirm: {  })
    }
}

extension CZImageEditor {
    
    // MARK: - showing picture
    private func refreshLayoutAndPreviews() {
        if parameters.attributes.steadyPanOffset == .zero && parameters.attributes.steadyZoomScale == 1 {
            zoomToFillFrame()
        }
        Task {
            await vm.loadFilterPreviews()
        }
    }
    
    private var showingImage: some View {
        Image(uiImage: vm.targetImage ?? UIColor.clear.uiImage())
            .scaleEffect(zoomScale)
            .offset(panOffset)
            .opacity(showOriginalImage ? 0 : 1)
    }
    
    private var originalImageToCompare: some View {
        Image(uiImage: vm.originImage ?? UIColor.clear.uiImage())
            .scaleEffect(initZoomScale)
            .opacity(showOriginalImage ? 1 : 0)
    }
    
    private var onAdjust: Bool {
        selectedEditOption == .rotation
    }
    private var campus: some View {
        ZStack {
            Color.black
                .doWithViewCoordinates(in: .local) { rect in
                    campusRect = rect
                }
            
            if changesWereMade {
                Color.clear
                    .overlay { originalImageToCompare }
            }
            
            if frameSize != .zero && originalPictureSize != .zero {
                Color.clear
                    .overlay { showingImage }
            }
                            
            cropMask(in: campusRect)
        }
        .clipped()
        .gesture(
            panGesture()
                .simultaneously(with: zoomGesture())
        )
        .onChange(of: vm.rotationPercent) { _ in
            alignTargetPictureByZooming(animated: false)
        }
        .onChange(of: frameSize) { newValue in
            if newValue != .zero {
                vm.frameSize = newValue
                refreshLayoutAndPreviews()
            }
        }
    }
    // MARK: - Filters
    private func filteredImageView(filteredImage: FilteredImage) -> some View {
        VStack(spacing: 8) {
            Text(LocalizedStringKey(localizationPrefix + filteredImage.name))
                .font(filterNameFont)
                .foregroundColor(.white)
            
            Image(uiImage: filteredImage.image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipped()
        }
        .onTapGesture {
            vm.selectedFilter = filteredImage.filter
            vm.applyFiltersToTarget()
        }
    }
    
    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(vm.filteredImages.sorted(by: { $0.id < $1.id })) { filtered in
                    filteredImageView(filteredImage: filtered)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: Edit options
    private func optionDisplayValue(option: EditOption) -> Double {
        let range = Double(option == .rotation ? 360 : 200)
        return (fetchOptionPercentValue(option: option) - 0.5) * range
    }
    
    private var editOptions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(EditOption.allCases, id: \.self) { option in
                    VStack(spacing: 8) {
                        Text(LocalizedStringKey(localizationPrefix + option.rawValue))
                            .font(filterNameFont)
                            .foregroundColor(.white)
                        
                        editOptionIcon(option: option)
                            .frame(width: 70, height: 70, alignment: .center)
                        
                        Text("\(optionDisplayValue(option: option), specifier: "%.0f")")
                            .opacity(fetchOptionPercentValue(option: option) == 0.5 ? 0 : 1)
                    }
                    .onTapGesture {
                        editingValue = optionDisplayValue(option: option)
                        savedEditingValue = editingValue
                        if option == .rotation {
                            savedEditPanOffset = vm.steadyPanOffset
                            savedEditZoomScale = vm.steadyZoomScale
                        }
                        withAnimation(selectAnimation) {
                            selectedEditOption = option
                        }
                    }
                }
            }
            
        }
    }
    
    private func editCertainOption(option: EditOption) -> some View {
        VStack(spacing: 8) {
            if option == .rotation {
                Slider(value: $editingValue, in: -180...180, step: 1)
                Text(LocalizedStringKey(localizationPrefix + "Rotation:")) + Text(" \(editingValue, specifier: "%.0f")")
            } else {
                Slider(value: $editingValue, in: -100...100, step: 1)
                Text(LocalizedStringKey(localizationPrefix + "\(option.rawValue):")) + Text(" \(editingValue, specifier: "%.0f")")
            }
        }
        .onChange(of: editingValue) { newValue in
            setValueToOption(value: newValue, option: option)
        }
    }
    
    // MARK: - Panels
    private var selectAnimation: Animation {
        Animation.easeIn(duration: 0.1)
    }
    
    private var changesWereMade: Bool {
        return vm.outputAttributes() != ImageEditorParameters.Attributes.init()
    }
    private var changesWereMadeThisTime: Bool {
        return vm.outputAttributes() != parameters.attributes
    }
    
    @ViewBuilder
    private var toolbarRightButton: some View {
        if changesWereMade && !changesWereMadeThisTime {
            TextButton(text: "Revert", color: .red, localizationPrefix: localizationPrefix) {
                vm.loadAttributes(attributes: .init())
                vm.targetImage = vm.originImage
                Task {
                    await vm.loadFilterPreviews()
                }
                parameters = .init(fullOriginalImage: vm.originFullImage, attributes: .init())
            }
        } else {
            TextButton(text: "Confirm", color: .white, localizationPrefix: localizationPrefix) {
                if let originFullImage = vm.originFullImage,
                   let finalImage = vm.cropImage(originalImage: originFullImage, applyColorFilters: true) {
                    image = finalImage
                    parameters = vm.outputParameters()
//                    print(parameters)
                }
                actionWhenConfirm?()
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private var middlePanel: some View {
        ZStack {
            Color.black
            
            if editType == .edit {
                if let selectedEditOption = selectedEditOption {
                    editCertainOption(option: selectedEditOption)
                } else {
                    editOptions
                }
            } else if !vm.filteredImages.isEmpty && editType == .filter {
                filtersView
            }
        }
        .frame(height: 150)
    }
    
    private func bottomPanel(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            if selectedEditOption == nil {
                Text(LocalizedStringKey(localizationPrefix + EditType.filter.rawValue))
                    .fontWeight(editType == .filter ? .bold : .regular)
                    .animation(.none, value: editType)
                    .frame(width: geo.size.width/2)
                    .onTapGesture {
                        withAnimation(selectAnimation) {
                            editType = .filter
                        }
                    }
                
                Text(LocalizedStringKey(localizationPrefix + EditType.edit.rawValue))
                    .fontWeight(editType == .edit ? .bold : .regular)
                    .animation(.none, value: editType)
                    .frame(width: geo.size.width/2)
                    .onTapGesture {
                        withAnimation(selectAnimation) {
                            editType = .edit
                        }
                    }
            } else {
                Text(LocalizedStringKey(localizationPrefix + "Cancel"))
                    .frame(width: geo.size.width/2)
                    .onTapGesture {
                        vm.steadyPanOffset = savedEditPanOffset
                        vm.steadyZoomScale = savedEditZoomScale
                        setValueToOption(value: savedEditingValue, option: selectedEditOption!)
                        withAnimation(selectAnimation) {
                            selectedEditOption = nil
                        }
                    }
                
                Text(LocalizedStringKey(localizationPrefix + "Done"))
                    .frame(width: geo.size.width/2)
                    .onTapGesture {
                        if selectedEditOption == .rotation {
                            Task {
                                await vm.loadFilterPreviews()
                            }
                        }
                        withAnimation(selectAnimation) {
                            selectedEditOption = nil
                        }
                    }
            }
        }
        .frame(height: 40)
        .background(Color.black)
    }
    
    // MARK: - enums
    
    enum EditType: String {
        case filter = "Filter"
        case edit = "Edit"
    }
    
    // MARK: - Edit Funcs
    private func editOptionIcon(option: EditOption) -> some View {
        return VStack {
            Group {
                switch option {
                case .rotation:
                    Image(systemName: "crop.rotate")
                        .resizable()
                        .scaledToFit()
                case .brightness:
                    Image(systemName: "sun.max")
                        .resizable()
                        .scaledToFit()
                case .contrast:
                    Image(systemName: "circle.righthalf.filled")
                        .resizable()
                        .scaledToFit()
                case .saturation:
                    Image(systemName: "drop")
                        .resizable()
                        .scaledToFit()
                case .sharpen:
                    Image(systemName: "triangle")
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(Angle(degrees: 180))
                case .warmth:
                    Image(systemName: "thermometer")
                        .resizable()
                        .scaledToFit()
                }
            }
            
        }
        .foregroundColor(Color.white)
        .frame(width: 40, height: 40)
    }
    
    private func setValueToOption(value: Double, option: EditOption) {
        switch option {
        case .rotation:
            vm.rotationPercent = (value + 180)/360
        case .brightness:
            vm.brightnessPercent = (value + 100)/200
        case .contrast:
            vm.contrastPercent = (value + 100)/200
        case .saturation:
            vm.saturationPercent = (value + 100)/200
        case .sharpen:
            vm.sharpenPercent = (value + 100)/200
        case .warmth:
            vm.warmthPercent = (value + 100)/200
        }
        vm.applyFiltersToTarget()
    }
    
    private func fetchOptionPercentValue(option: EditOption) -> Double {
        switch option {
        case .rotation: return vm.rotationPercent
        case .brightness: return vm.brightnessPercent
        case .contrast: return vm.contrastPercent
        case .saturation: return vm.saturationPercent
        case .sharpen: return vm.sharpenPercent
        case .warmth: return vm.warmthPercent
        }
    }
    
    // MARK: - Cropping
    private func HoleShapeMask(frameRect: CGRect) -> Path {
        var shape = Rectangle().path(in: frameRect)
        let center = frameRect.center
        let maskOrigin = center - frameSize / 2
        if frame == .circle {
            shape.addPath(Circle().path(in: CGRect(origin: maskOrigin, size: frameSize)))
        } else {
            shape.addPath(Rectangle().path(in: CGRect(origin: maskOrigin, size: frameSize)))
        }
        return shape
    }
    
    private func cropMask(in rect: CGRect) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(onAdjust ? 0.5 : 1))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask(HoleShapeMask(frameRect: rect).fill(style: FillStyle(eoFill: true)))
            
            if onAdjust {
                Group {
                    if frame != .circle && frame != .square {
                        Rectangle()
                            .stroke(style: .init(lineWidth: 0.9, dash: [5]))
                            .opacity(0.75)
                            .frame(width: min(frameSize.width, frameSize.height), height: min(frameSize.width, frameSize.height))
                    }
                    
                    switch frame {
                    case .circle:
                        Circle().stroke()
                    default:
                        Rectangle().stroke()
                    }
                }
                .frame(width: frameSize.width, height: frameSize.height)
                .foregroundColor(.white)
                .position(rect.center)
                .contentShape(Rectangle())
                .gesture(doubleTapToZoomFillFrame())
            }
        }
    }
    
    // MARK: - Picture Alignment
    private var animation: Animation {
        Animation.easeOut(duration: 0.2)
    }
    
    private func rotatedPicPoints() -> (a: CGSize, b: CGSize, c: CGSize, d: CGSize) {
        let picCenter = panOffset.reverseHeight()
        let halfPicWidth = showingPictureSize.width / 2
        let halfPicHeight = showingPictureSize.height / 2
        
//        print("showingPictureSize: \(showingPictureSize), zoomScale: \(zoomScale), steadyZoomScale: \(vm.steadyZoomScale)")
        
        let pointA = CGSize(width: picCenter.width - halfPicWidth, height: picCenter.height + halfPicHeight)
        let pointB = CGSize(width: picCenter.width + halfPicWidth, height: picCenter.height + halfPicHeight)
        let pointC = CGSize(width: picCenter.width + halfPicWidth, height: picCenter.height - halfPicHeight)
        let pointD = CGSize(width: picCenter.width - halfPicWidth, height: picCenter.height - halfPicHeight)
        let rotatedPointA = pointA.rotatedVector(radians: Double.pi * 2 - vm.rotatedAngle, center: picCenter)
        let rotatedPointB = pointB.rotatedVector(radians: Double.pi * 2 - vm.rotatedAngle, center: picCenter)
        let rotatedPointC = pointC.rotatedVector(radians: Double.pi * 2 - vm.rotatedAngle, center: picCenter)
        let rotatedPointD = pointD.rotatedVector(radians: Double.pi * 2 - vm.rotatedAngle, center: picCenter)
        return (rotatedPointA, rotatedPointB, rotatedPointC, rotatedPointD)
    }
    
    private func framePointOffsetOfLine(_ framePoint: CGSize, point1: CGSize, point2: CGSize) -> CGFloat {
        let a = point2.height - point1.height
        let b = point1.width - point2.width
        let c = point2.width * point1.height - point1.width * point2.height
        let dividend = a * framePoint.width + b * framePoint.height + c
        let divider = sqrt(a*a + b*b)
        let d = dividend / divider
        return d
    }
    
    private func frameToPicOffset() -> (da: CGFloat, ab: CGFloat, bc: CGFloat, cd: CGFloat) {
        let frameTopLeft = CGSize(width: -frameSize.width/2, height: frameSize.height/2)
        let frameTopRight = CGSize(width: frameSize.width/2, height: frameSize.height/2)
        let frameBottomRight = CGSize(width: frameSize.width/2, height: -frameSize.height/2)
        let frameBottomLeft = CGSize(width: -frameSize.width/2, height: -frameSize.height/2)
        
        var frameOffsetDA: CGFloat = 0
        var frameOffsetAB: CGFloat = 0
        var frameOffsetBC: CGFloat = 0
        var frameOffsetCD: CGFloat = 0
        
        let rotatedPicPoints = rotatedPicPoints()
        
        if vm.rotatedDegrees >= 0 && vm.rotatedDegrees <= 90 {
            frameOffsetDA = framePointOffsetOfLine(frameTopLeft, point1: rotatedPicPoints.d, point2: rotatedPicPoints.a)
            frameOffsetAB = framePointOffsetOfLine(frameTopRight, point1: rotatedPicPoints.a, point2: rotatedPicPoints.b)
            frameOffsetBC = framePointOffsetOfLine(frameBottomRight, point1: rotatedPicPoints.b, point2: rotatedPicPoints.c)
            frameOffsetCD = framePointOffsetOfLine(frameBottomLeft, point1: rotatedPicPoints.c, point2: rotatedPicPoints.d)
        } else if vm.rotatedDegrees > 90 && vm.rotatedDegrees <= 180 {
            frameOffsetDA = framePointOffsetOfLine(frameTopRight, point1: rotatedPicPoints.d, point2: rotatedPicPoints.a)
            frameOffsetAB = framePointOffsetOfLine(frameBottomRight, point1: rotatedPicPoints.a, point2: rotatedPicPoints.b)
            frameOffsetBC = framePointOffsetOfLine(frameBottomLeft, point1: rotatedPicPoints.b, point2: rotatedPicPoints.c)
            frameOffsetCD = framePointOffsetOfLine(frameTopLeft, point1: rotatedPicPoints.c, point2: rotatedPicPoints.d)
        } else if vm.rotatedDegrees < 0 && vm.rotatedDegrees >= -90 {
            frameOffsetDA = framePointOffsetOfLine(frameBottomLeft, point1: rotatedPicPoints.d, point2: rotatedPicPoints.a)
            frameOffsetAB = framePointOffsetOfLine(frameTopLeft, point1: rotatedPicPoints.a, point2: rotatedPicPoints.b)
            frameOffsetBC = framePointOffsetOfLine(frameTopRight, point1: rotatedPicPoints.b, point2: rotatedPicPoints.c)
            frameOffsetCD = framePointOffsetOfLine(frameBottomRight, point1: rotatedPicPoints.c, point2: rotatedPicPoints.d)
        } else if vm.rotatedDegrees < -90 && vm.rotatedDegrees >= -180 {
            frameOffsetDA = framePointOffsetOfLine(frameBottomRight, point1: rotatedPicPoints.d, point2: rotatedPicPoints.a)
            frameOffsetAB = framePointOffsetOfLine(frameBottomLeft, point1: rotatedPicPoints.a, point2: rotatedPicPoints.b)
            frameOffsetBC = framePointOffsetOfLine(frameTopLeft, point1: rotatedPicPoints.b, point2: rotatedPicPoints.c)
            frameOffsetCD = framePointOffsetOfLine(frameTopRight, point1: rotatedPicPoints.c, point2: rotatedPicPoints.d)
        }
        
        return (frameOffsetDA, frameOffsetAB, frameOffsetBC, frameOffsetCD)
    }
    
    private func alignTargetPictureByPanning() {
        guard targetPictureSize != .zero else { return }
        let offsets = frameToPicOffset()
        
        let offsetVectorDA = CGSize(width: cos(Double.pi - vm.rotatedAngle), height: sin(Double.pi - vm.rotatedAngle)) * -offsets.da
        let offsetVectorAB = CGSize(width: cos(Double.pi/2 - vm.rotatedAngle), height: sin(Double.pi/2 - vm.rotatedAngle)) * -offsets.ab
        let offsetVectorBC = CGSize(width: cos( -vm.rotatedAngle), height: sin( -vm.rotatedAngle)) * -offsets.bc
        let offsetVectorCD = CGSize(width: cos(-Double.pi/2 - vm.rotatedAngle), height: sin(-Double.pi/2 - vm.rotatedAngle)) * -offsets.cd
                
        var picOffset = CGSize.zero
        if offsets.da < 0 { picOffset = picOffset + offsetVectorDA }
        if offsets.ab < 0 { picOffset = picOffset + offsetVectorAB }
        if offsets.bc < 0 { picOffset = picOffset + offsetVectorBC }
        if offsets.cd < 0 { picOffset = picOffset + offsetVectorCD }
        
        withAnimation(animation) {
            vm.steadyPanOffset = vm.steadyPanOffset + (picOffset.reverseHeight().rotatedVector(radians: -vm.rotatedAngle)/zoomScale)
        }
    }
    
    private func alignTargetPictureByZooming(animated: Bool = true) {
        guard targetPictureSize != .zero else { return }
        let offsets = frameToPicOffset()
//        print(offsets)
        if max(offsets.da, offsets.ab, offsets.bc, offsets.cd) < 0 {
            zoomToFillFrame()
            return
        }
        
        let largestOffset = min(offsets.da, offsets.ab, offsets.bc, offsets.cd, 0)
        guard largestOffset < 0 else { return }

        var scale: CGFloat = 1
        let rotatedPicPoints = rotatedPicPoints()
        if offsets.da == largestOffset {
            let daToFrameCenter = abs(framePointOffsetOfLine(CGSize.zero, point1: rotatedPicPoints.d, point2: rotatedPicPoints.a))
            scale = (daToFrameCenter - largestOffset) / daToFrameCenter
        } else if offsets.ab == largestOffset {
            let abToFrameCenter = abs(framePointOffsetOfLine(CGSize.zero, point1: rotatedPicPoints.a, point2: rotatedPicPoints.b))
            scale = (abToFrameCenter - largestOffset) / abToFrameCenter
        } else if offsets.bc == largestOffset {
            let bcToFrameCenter = abs(framePointOffsetOfLine(CGSize.zero, point1: rotatedPicPoints.b, point2: rotatedPicPoints.c))
            scale = (bcToFrameCenter - largestOffset) / bcToFrameCenter
        } else if offsets.cd == largestOffset {
            let cdToFrameCenter = abs(framePointOffsetOfLine(CGSize.zero, point1: rotatedPicPoints.c, point2: rotatedPicPoints.d))
            scale = (cdToFrameCenter - largestOffset) / cdToFrameCenter
        }
            
        if animated {
            withAnimation(animation) {
                vm.steadyZoomScale = vm.steadyZoomScale * scale
            }
        } else {
            vm.steadyZoomScale = vm.steadyZoomScale * scale
        }
    }
    
    // MARK: - Size vars
    private var campusSize: CGSize {
        campusRect.size
    }
    
    private var frameSize: CGSize {
        frame.frameSize(imageSize: vm.originImage?.size ?? .zero, campusSize: campusSize)
    }
    
    private var originalPictureSize: CGSize {
        vm.originImage?.size ?? .zero
    }
    
    private var targetPictureSize: CGSize {
        vm.targetImage?.size ?? .zero
    }
    
    private var showingPictureSize: CGSize {
        originalPictureSize * zoomScale
    }
    
    
    // MARK: - Zooming
    private var initZoomScale: CGFloat {
        guard originalPictureSize != .zero else { return 1 }
        return frameSize.maxRatio(with: originalPictureSize)
    }
    private var extraZoomScale: CGFloat {
        vm.steadyZoomScale * gestureZoomScale
    }
    
    private var zoomScale: CGFloat {
        initZoomScale * extraZoomScale
    }
    
    private func zoomToFillFrame() {
        guard targetPictureSize != .zero else { return }
        withAnimation(animation) {
            vm.steadyPanOffset = .zero
        }
        let offsets = frameToPicOffset()
        let rotatedPicPoints = rotatedPicPoints()

        let daToFrameCenter = abs(framePointOffsetOfLine(CGSize.zero, point1: rotatedPicPoints.d, point2: rotatedPicPoints.a))
        let scaleToDA = (daToFrameCenter - offsets.da) / daToFrameCenter
        let abToFrameCenter = abs(framePointOffsetOfLine(CGSize.zero, point1: rotatedPicPoints.a, point2: rotatedPicPoints.b))
        let scaleToAB = (abToFrameCenter - offsets.ab) / abToFrameCenter
        let bcToFrameCenter = abs(framePointOffsetOfLine(CGSize.zero, point1: rotatedPicPoints.b, point2: rotatedPicPoints.c))
        let scaleToBC = (bcToFrameCenter - offsets.bc) / bcToFrameCenter
        let cdToFrameCenter = abs(framePointOffsetOfLine(CGSize.zero, point1: rotatedPicPoints.c, point2: rotatedPicPoints.d))
        let scaleToCD = (cdToFrameCenter - offsets.cd) / cdToFrameCenter
        let maxScale = max(scaleToDA, scaleToAB, scaleToBC, scaleToCD)

        withAnimation(animation) {
            vm.steadyZoomScale = vm.steadyZoomScale * maxScale
        }
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                if onAdjust {
                    gestureZoomScale = latestGestureScale
                }
            }
            .onEnded { gestureScaleAtEnd in
                if onAdjust {
                    vm.steadyZoomScale *= gestureScaleAtEnd
                    alignTargetPictureByZooming()
                }
            }
    }
    
    private func doubleTapToZoomFillFrame() -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                if onAdjust {
                    zoomToFillFrame()
                }
            }
    }
    
    // MARK: - Panning
    private var panOffset: CGSize {
        let panOffsetBeforeRotation = (vm.steadyPanOffset + gesturePanOffset) * zoomScale
        return panOffsetBeforeRotation.rotatedVector(radians: vm.rotatedAngle)
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                if onAdjust {
                    gesturePanOffset = latestDragGestureValue.translation.rotatedVector(radians: -vm.rotatedAngle) / zoomScale
                }
            }
            .onEnded { finalDragGestureValue in
                if onAdjust {
                    vm.steadyPanOffset = vm.steadyPanOffset + (finalDragGestureValue.translation.rotatedVector(radians: -vm.rotatedAngle) / zoomScale)
                    alignTargetPictureByPanning()
                }
            }
    }
    
}

