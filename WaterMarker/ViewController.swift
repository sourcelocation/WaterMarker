//
//  ViewController.swift
//  WaterMarker
//
//  Created by Матвей Анисович on 16.11.2020.
//

import Cocoa

class ViewController: NSViewController {
    
    var selectedWatermarkOpacity = 0.25
    var selectedWatermarkSizeRatio:CGFloat = 0.33
    var selectedImagesURLs:[URL]?
    var selectedWatermarkURL:URL?
    var exportPathURL:URL?
    var exportFilesInExtension:NSBitmapImageRep.FileType = .png
    var results:[NSImage]?
    var isWatermarkSingleColor = false
    
    var previewOriginalImage:NSImage?
    
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var previewImage: NSImageView!
    @IBOutlet weak var selectedImagesLabelCount: NSTextField!
    @IBOutlet weak var watermarkNameLabel: NSTextField!
    @IBAction func opacitySliderValueChanged(_ sender: NSSlider) {
        self.selectedWatermarkOpacity = sender.doubleValue / 100.0
        updatePreviewImage()
    }
    @IBAction func singleColorCheckValueChanged(_ sender: NSButton) {
        isWatermarkSingleColor = sender.state == .on ? true : false
        colorWell.isEnabled = isWatermarkSingleColor
        updatePreviewImage()
    }
    @IBAction func colorWellColorChanged(_ sender: NSColorWell) {
        updatePreviewImage()
    }
    @IBAction func sizeSliderValueChanged(_ sender: NSSlider) {
        self.selectedWatermarkSizeRatio = CGFloat(sender.doubleValue / 100.0)
        updatePreviewImage()
    }
    @IBAction func selectImagesClicked(_ sender: NSButton) {
        let dialog = NSOpenPanel()
        dialog.title                   = "Choose .png files"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = true
        dialog.allowedFileTypes        = ["png","jpg","heic"]
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.urls // Pathname of the file
            selectedImagesURLs = result
            print(selectedImagesURLs!)
            selectedImagesLabelCount.stringValue = "\(selectedImagesURLs?.count ?? 0) images selected"
            
            previewOriginalImage = NSImage(contentsOf: selectedImagesURLs![0])!
            
            updatePreviewImage()
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    @IBAction func selectWatermarkButtonClicked(_ sender: NSButton) {
        let dialog = NSOpenPanel()
        dialog.title                   = "Choose a .png watermark"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["png"]
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url
            selectedWatermarkURL = result
            watermarkNameLabel.stringValue = "\(result?.lastPathComponent ?? "No image selected")"
            updatePreviewImage()
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    @IBAction func fileTypeSegmentChanged(_ sender: NSSegmentedControl) {
        self.exportFilesInExtension = sender.selectedSegment == 0 ? .png : .jpeg
    }
    @IBAction func exportButtonClicked(_ sender: NSButton) {
        if selectedWatermarkURL != nil, selectedImagesURLs != nil {
            let dialog = NSSavePanel()
            
            dialog.title = "Save files"
            dialog.nameFieldLabel = "Ending (eg. with_watermark)"
            dialog.nameFieldStringValue = "with_watermark"
            dialog.showsResizeIndicator = false
            dialog.canCreateDirectories = true
            dialog.showsHiddenFiles = false
            dialog.allowedFileTypes = ["png"]
            
            if (dialog.runModal() == NSApplication.ModalResponse.OK) {
                let result = dialog.url
                if (result != nil) {
                    exportPathURL = result
                    var images:[NSImage] = []
                    for url in selectedImagesURLs ?? [] {
                        images.append(NSImage(contentsOf: url)!)
                    }
                    self.results = putImage(on: images, watermark: NSImage(contentsOf: selectedWatermarkURL!)!)
                    
                    for imageIndex in 0..<self.results!.count {
                        let image = self.results![imageIndex]
                        let urlToWriteTo = result?.deletingLastPathComponent().appendingPathComponent("\(selectedImagesURLs![imageIndex].deletingPathExtension().lastPathComponent)\(dialog.nameFieldStringValue).\(self.exportFilesInExtension == .png ? "png" : "jpg")")
                        image.writePNG(toURL: urlToWriteTo!, type: self.exportFilesInExtension)
                        print("saved at \(urlToWriteTo)")
                    }
                }
            } else {
                print("Cancel")
                return // User clicked cancel
            }
        } else {
            let alert = NSAlert()
            alert.messageText = "Can not export!"
            alert.informativeText = "Import images and a watermark first."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private func updatePreviewImage() {
        if selectedWatermarkURL != nil, selectedImagesURLs != nil, previewOriginalImage != nil {
            var watermark = NSImage(contentsOf: selectedWatermarkURL!)!
            if isWatermarkSingleColor {
                let color = colorWell.color
                watermark.isTemplate = true
                watermark = watermark.image(with: color)
            }
//
            let imageSize = previewOriginalImage!.size / 3
            
            self.results = putImage(on: [(previewOriginalImage?.copy() as! NSImage).resized(to: imageSize)!], watermark: watermark)
            self.previewImage.image = results?.first
        }
    }
    
    private func putImage(on images:[NSImage], watermark:NSImage) -> [NSImage] {
        var finalImages:[NSImage] = []
        for image1 in images {
            let image = NSImage(size: CGSize(width: image1.size.width, height: image1.size.height), actions: { ctx in
                // Drawing commands here for example:
                image1.draw(in: CGRect(origin: CGPoint.zero, size: image1.size))
                
                let watermarkSize = NSSize(width: image1.size.width * selectedWatermarkSizeRatio, height: watermark.size.height * (image1.size.width * selectedWatermarkSizeRatio / watermark.size.width))
                let watermarkPoint = NSPoint(x: image1.size.width / 2.0 - watermarkSize.width / 2, y: image1.size.height / 2.0 - watermarkSize.height / 2)
                let watermarkRect = CGRect(origin: watermarkPoint, size: watermarkSize)
                watermark.draw(in: watermarkRect,
                               from: NSRect.zero,
                               operation: .sourceOver,
                               fraction: CGFloat(selectedWatermarkOpacity))
            })
            finalImages.append(image)
        }
        
        return finalImages
    }
}


extension NSImage {
    convenience init(size: CGSize, actions: (CGContext) -> Void) {
        self.init(size: size)
        lockFocusFlipped(false)
        actions(NSGraphicsContext.current!.cgContext)
        unlockFocus()
    }
}

public extension NSImage {
    func writePNG(toURL url: URL, type:NSBitmapImageRep.FileType) {
        
        guard let data = tiffRepresentation,
              let rep = NSBitmapImageRep(data: data),
              let imgData = rep.representation(using: type, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)]) else {
            
            print("\(self.self) Error Function '\(#function)' Line: \(#line) No tiff rep found for image writing to \(url)")
            return
        }
        
        do {
            try imgData.write(to: url)
        }catch let error {
            print("\(self.self) Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
        }
    }
}
extension NSImage {
    func image(with tintColor: NSColor) -> NSImage {
        if self.isTemplate == false {
            return self
        }
        
        let image = self.copy() as! NSImage
        image.lockFocus()
        
        tintColor.set()
        
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceIn)
        
        image.unlockFocus()
        image.isTemplate = false
        
        return image
    }
}
extension NSImage {
    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }

        return nil
    }
}
