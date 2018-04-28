//
//  NSImage+Extensions.swift
//  Haauti
//
//  Created by Perceval FARAMAZ on 23/02/2018.
//  Copyright © 2018 deicoon. All rights reserved.
//

import Cocoa

extension NSImage {
    func imageWithTint(color: NSColor) -> NSImage {
        guard let tinted = self.copy() as? NSImage else { return self }
        tinted.lockFocus()
        color.set()
        
        let imageRect = NSRect(origin: NSZeroPoint, size: self.size)
        imageRect.fill(using: .sourceAtop)
        
        tinted.unlockFocus()
        tinted.isTemplate = false
        return tinted
    }
    
    static var mapMarkerIcon : NSImage = {
        var hereImage = NSImage(size: NSMakeSize(11, 14))
        hereImage.lockFocus()
        //// noun_408397_cc.svg Group ; Ecem Afacan/NounProject
        //// Color Declarations
        let fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        //// Shape Drawing
        let shapePath = NSBezierPath()
        shapePath.move(to: NSPoint(x: 9.65, y: 9.17))
        shapePath.curve(to: NSPoint(x: 5.03, y: 13.8), controlPoint1: NSPoint(x: 9.65, y: 11.74), controlPoint2: NSPoint(x: 7.59, y: 13.8))
        shapePath.curve(to: NSPoint(x: 0.4, y: 9.17), controlPoint1: NSPoint(x: 2.46, y: 13.8), controlPoint2: NSPoint(x: 0.4, y: 11.74))
        shapePath.curve(to: NSPoint(x: 2.35, y: 3.78), controlPoint1: NSPoint(x: 0.4, y: 7.61), controlPoint2: NSPoint(x: 1.18, y: 5.33))
        shapePath.line(to: NSPoint(x: 5.03, y: -0.2))
        shapePath.line(to: NSPoint(x: 7.7, y: 3.8))
        shapePath.line(to: NSPoint(x: 7.7, y: 3.8))
        shapePath.curve(to: NSPoint(x: 9.65, y: 9.17), controlPoint1: NSPoint(x: 8.88, y: 5.33), controlPoint2: NSPoint(x: 9.65, y: 7.61))
        shapePath.close()
        shapePath.move(to: NSPoint(x: 5.03, y: 6.5))
        shapePath.curve(to: NSPoint(x: 2.51, y: 9.02), controlPoint1: NSPoint(x: 3.63, y: 6.5), controlPoint2: NSPoint(x: 2.51, y: 7.63))
        shapePath.curve(to: NSPoint(x: 5.03, y: 11.55), controlPoint1: NSPoint(x: 2.51, y: 10.41), controlPoint2: NSPoint(x: 3.63, y: 11.55))
        shapePath.curve(to: NSPoint(x: 7.54, y: 9.03), controlPoint1: NSPoint(x: 6.42, y: 11.55), controlPoint2: NSPoint(x: 7.54, y: 10.42))
        shapePath.curve(to: NSPoint(x: 5.03, y: 6.5), controlPoint1: NSPoint(x: 7.54, y: 7.64), controlPoint2: NSPoint(x: 6.42, y: 6.5))
        shapePath.close()
        fillColor.setFill()
        shapePath.fill()

        
        hereImage.isTemplate = true
        hereImage.unlockFocus()
        
        return hereImage
    }()
    
    static var homeIcon : NSImage = {
        return NSImage(named: NSImage.Name(rawValue: "NSHomeTemplate"))!
    }()
    
    static var tripleDot : NSImage = {
        /*let asciiArray = [
            ". A . . . B . . . C .",
            "A . A . B . B . C . C",
            ". A . . . B . . . C ."]
        
        let asciiComputed = NSImage.init(asciiRepresentation: asciiArray, color: NSColor.white, shouldAntialias: false)*/
        var dotImage = NSImage(size: NSMakeSize(34, 10))
        dotImage.lockFocus()
        //// Color Declarations
        let color = NSColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        //// Oval Drawing
        let ovalPath = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: 10, height: 10))
        color.setFill()
        ovalPath.fill()
        
        
        //// Oval 2 Drawing
        let oval2Path = NSBezierPath(ovalIn: NSRect(x: 12, y: 0, width: 10, height: 10))
        color.setFill()
        oval2Path.fill()
        
        
        //// Oval 3 Drawing
        let oval3Path = NSBezierPath(ovalIn: NSRect(x: 24, y: 0, width: 10, height: 10))
        color.setFill()
        oval3Path.fill()
        
        dotImage.isTemplate = true
        dotImage.unlockFocus()
        
        return dotImage.imageWithTint(color: NSColor.white).resizeWhileMaintainingAspectRatioToSize(size: NSMakeSize(7, 7))!
    }()
}

//https://gist.github.com/MaciejGad/11d8469b218817290ee77012edb46608
extension NSImage {
    
    /// Returns the height of the current image.
    var height: CGFloat {
        return self.size.height
    }
    
    /// Returns the width of the current image.
    var width: CGFloat {
        return self.size.width
    }
    
    /// Returns a png representation of the current image.
    var PNGRepresentation: Data? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .png, properties: [:])
        }
        
        return nil
    }
    
    ///  Copies the current image and resizes it to the given size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func copy(size: NSSize) -> NSImage? {
        // Create a new rect with given width and height
        let frame = NSMakeRect(0, 0, size.width, size.height)
        
        // Get the best representation for the given size.
        guard let rep = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create an empty image with the given size.
        let img = NSImage(size: size)
        
        // Set the drawing context and make sure to remove the focus before returning.
        img.lockFocus()
        defer { img.unlockFocus() }
        
        // Draw the new image
        if rep.draw(in: frame) {
            return img
        }
        
        // Return nil in case something went wrong.
        return nil
    }
    
    ///  Copies the current image and resizes it to the size of the given NSSize, while
    ///  maintaining the aspect ratio of the original image.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func resizeWhileMaintainingAspectRatioToSize(size: NSSize) -> NSImage? {
        let newSize: NSSize
        
        let widthRatio  = size.width / self.width
        let heightRatio = size.height / self.height
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio), height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio), height: floor(self.height * heightRatio))
        }
        
        return self.copy(size: newSize)
    }
    
    ///  Copies and crops an image to the supplied size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The cropped copy of the given image.
    func crop(size: NSSize) -> NSImage? {
        // Resize the current image, while preserving the aspect ratio.
        guard let resized = self.resizeWhileMaintainingAspectRatioToSize(size: size) else {
            return nil
        }
        // Get some points to center the cropping area.
        let x = floor((resized.width - size.width) / 2)
        let y = floor((resized.height - size.height) / 2)
        
        // Create the cropping frame.
        let frame = NSMakeRect(x, y, size.width, size.height)
        
        // Get the best representation of the image for the given cropping frame.
        guard let rep = resized.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create a new image with the new size
        let img = NSImage(size: size)
        
        img.lockFocus()
        defer { img.unlockFocus() }
        
        if rep.draw(in: NSMakeRect(0, 0, size.width, size.height),
                    from: frame,
                    operation: NSCompositingOperation.copy,
                    fraction: 1.0,
                    respectFlipped: false,
                    hints: [:]) {
            // Return the cropped image.
            return img
        }
        
        // Return nil in case anything fails.
        return nil
    }
    
    ///  Saves the PNG representation of the current image to the HD.
    ///
    /// - parameter url: The location url to which to write the png file.
    func savePNGRepresentationToURL(url: URL) throws {
        if let png = self.PNGRepresentation {
            try png.write(to: url, options: .atomicWrite)
        }
    }
}
