//
//  Image.swift
//  HyperCard
//
//  Created by Pierre Lorenzi on 13/02/2016.
//  Copyright © 2016 Pierre Lorenzi. All rights reserved.
//

import AppKit


/// A 1-bit image without mask
/// <p>
/// We don't use a Cocoa image because there are a lot of specific processes in 1-bit images.
public struct Image {
    
    /// The bits, stored in 32-bit integers. A row always starts at the beginning of an integer,
    /// so there may be unused bits at the end of every row for 32-bit alignment.
    public var data: [UInt32]
    
    /// Width of the image, in pixels
    public let width: Int
    
    /// Height of the image, in pixels
    public let height: Int
    
    /// Number of 32-bit integers that make up a row in the data
    public let integerCountInRow: Int
    
    /// Main constructor. Build a blank image.
    public init(width: Int, height: Int) {
        
        /* Compute the bounds */
        self.width = width
        self.height = height
        let integerCountInRow = upToMultiple(width, 32) / 32
        self.integerCountInRow = integerCountInRow
        
        /* Build the color data */
        let integerCount = integerCountInRow * height
        self.data = [UInt32](repeating: 0, count: integerCount)
        
    }
    
    /// Returns whether or not the pixel at (x,y) is activated.
    /// <p>
    /// x is counted from the left, y from the top.
    public subscript(x: Int, y: Int) -> Bool {
        get {
            let integerIndexInRow = x / 32
            let indexInInteger = 31 - x & 31
            let integer = data[ y * integerCountInRow + integerIndexInRow ]
            let bit = (integer >> UInt32(indexInInteger)) & 1
            return bit == 1
        }
        set {
            /* Write the mask */
            let indexInInteger = 31 - x & 31
            let mask = UInt32(1 << indexInInteger)
            
            /* Locate the integer */
            let integerIndexInRow = x / 32
            let integerIndex =  y * integerCountInRow + integerIndexInRow
            
            /* Change the integer */
            let integer = data[integerIndex]
            let newInteger = (newValue) ? integer | mask : integer & ~mask
            data[integerIndex] = newInteger
        }
    }
    
}


struct RgbColor {
    var a: UInt8
    var r: UInt8
    var g: UInt8
    var b: UInt8
}

let RgbWhite = RgbColor(a: 255, r: 255, g: 255, b: 255)
let RgbBlack = RgbColor(a: 255, r: 0, g: 0, b: 0)
let RgbTransparent = RgbColor(a: 0, r: 255, g: 255, b: 255)

let RgbColorSpace = CGColorSpaceCreateDeviceRGB()
let BitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
let BitmapInfoNotTransparent:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
let BitsPerComponent = 8
let BitsPerPixel = 32


public extension Image {
    
    /// Converts a HyperCard image to a Cocoa image
    public func convertToRgb() -> NSImage {
        
        var pixels = [RgbColor](repeating: RgbWhite, count: self.width*self.height)
        for x in 0..<self.width {
            for y in 0..<self.height {
                pixels[x + y*self.width] = self[x, y] ? RgbBlack : RgbWhite
            }
        }
        let data = NSMutableData(bytes: &pixels, length: pixels.count * MemoryLayout<RgbColor>.size)
        let providerRef = CGDataProvider(data: data)
        let cgimage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: BitsPerComponent,
            bitsPerPixel: BitsPerPixel,
            bytesPerRow: width * MemoryLayout<RgbColor>.size,
            space: RgbColorSpace,
            bitmapInfo: BitmapInfoNotTransparent,
            provider: providerRef!,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent)
        
        return NSImage(cgImage: cgimage!, size: NSZeroSize)
    }
    
}




