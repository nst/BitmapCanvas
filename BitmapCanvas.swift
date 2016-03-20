//
//  main.swift
//  BitmapCanvas
//
//  Created by nst on 04/01/16.
//  Copyright © 2016 Nicolas Seriot. All rights reserved.
//

import Cocoa

var Crayons = NSColorList(named: "Crayons")!

extension NSColorList {
    subscript (key:String) -> NSColor {
        return self.colorWithKey(key)!
    }
}

infix operator * { associativity right precedence 155 }

func *(left:CGFloat, right:Int) -> CGFloat
{ return left * CGFloat(right) }

func *(left:Int, right:CGFloat) -> CGFloat
{ return CGFloat(left) * right }

func *(left:CGFloat, right:Double) -> CGFloat
{ return left * CGFloat(right) }

func *(left:Double, right:CGFloat) -> CGFloat
{ return CGFloat(left) * right }

infix operator + { associativity right precedence 145 }

func +(left:CGFloat, right:Int) -> CGFloat
{ return left + CGFloat(right) }

func +(left:Int, right:CGFloat) -> CGFloat
{ return CGFloat(left) + right }

func +(left:CGFloat, right:Double) -> CGFloat
{ return left + CGFloat(right) }

func +(left:Double, right:CGFloat) -> CGFloat
{ return CGFloat(left) + right }

infix operator - { associativity right precedence 145 }

func -(left:CGFloat, right:Int) -> CGFloat
{ return left - CGFloat(right) }

func -(left:Int, right:CGFloat) -> CGFloat
{ return CGFloat(left) - right }

func -(left:CGFloat, right:Double) -> CGFloat
{ return left - CGFloat(right) }

func -(left:Double, right:CGFloat) -> CGFloat
{ return CGFloat(left) - right }

//

func P(x:CGFloat, _ y: CGFloat) -> NSPoint {
    return NSMakePoint(x, y)
}

func R(x:CGFloat, _ y:CGFloat, _ w:CGFloat, _ h:CGFloat) -> NSRect {
    return NSMakeRect(x, y, w, h)
}

func R(x:Int, _ y:Int, _ w:Int, _ h:Int) -> NSRect {
    return NSMakeRect(CGFloat(x), CGFloat(y), CGFloat(w), CGFloat(h))
}

class BitmapCanvas {
    
    let bitmapImageRep : NSBitmapImageRep
    let context : NSGraphicsContext
    
    var cgContext : CGContext {
        return context.CGContext
    }
    
    var width : CGFloat {
        return bitmapImageRep.size.width
    }
    
    var height : CGFloat {
        return bitmapImageRep.size.height
    }
    
    func setAllowsAntialiasing(antialiasing : Bool) {
        CGContextSetAllowsAntialiasing(cgContext, antialiasing)
    }
    
    init(_ width:Int, _ height:Int, _ background:ConvertibleToNSColor? = nil) {
        
        self.bitmapImageRep = NSBitmapImageRep(
            bitmapDataPlanes:nil,
            pixelsWide:width,
            pixelsHigh:height,
            bitsPerSample:8,
            samplesPerPixel:4,
            hasAlpha:true,
            isPlanar:false,
            colorSpaceName:NSDeviceRGBColorSpace,
            bytesPerRow:width*4,
            bitsPerPixel:32)!
        
        self.context = NSGraphicsContext(bitmapImageRep: bitmapImageRep)!
        
        NSGraphicsContext.setCurrentContext(context)
        
        setAllowsAntialiasing(false)
        
        if let b = background {
            
            let rect = NSMakeRect(0, 0, CGFloat(width), CGFloat(height))
            
            context.saveGraphicsState()
            
            b.color.setFill()
            NSBezierPath.fillRect(rect)
            
            context.restoreGraphicsState()
        }
        
        // makes coordinates start upper left
        CGContextTranslateCTM(cgContext, 0, CGFloat(height))
        CGContextScaleCTM(cgContext, 1.0, -1.0)
    }
    
    private func _colorIsEqual(p:NSPoint, _ pixelBuffer:UnsafePointer<UInt8>, _ rgba:(UInt8,UInt8,UInt8,UInt8)) -> Bool {
        
        let offset = 4 * ((Int(self.width) * Int(p.y) + Int(p.x)))
        
        let r = pixelBuffer[offset]
        let g = pixelBuffer[offset+1]
        let b = pixelBuffer[offset+2]
        let a = pixelBuffer[offset+3]
        
        if r != rgba.0 { return false }
        if g != rgba.1 { return false }
        if b != rgba.2 { return false }
        if a != rgba.3 { return false }
        
        return true
    }
    
    private func _color(p:NSPoint, pixelBuffer:UnsafePointer<UInt8>) -> NSColor {
        
        let offset = 4 * ((Int(self.width) * Int(p.y) + Int(p.x)))
        
        let r = pixelBuffer[offset]
        let g = pixelBuffer[offset+1]
        let b = pixelBuffer[offset+2]
        let a = pixelBuffer[offset+3]
        
        return NSColor(
            calibratedRed: CGFloat(Double(r)/255.0),
            green: CGFloat(Double(g)/255.0),
            blue: CGFloat(Double(b)/255.0),
            alpha: CGFloat(Double(a)/255.0))
    }
    
    func color(p:NSPoint) -> NSColor {
        
        let pixelBuffer = UnsafeMutablePointer<UInt8>(CGBitmapContextGetData(cgContext))
        
        return _color(p, pixelBuffer:pixelBuffer)
    }
    
    private func _setColor(p:NSPoint, pixelBuffer:UnsafeMutablePointer<UInt8>, normalizedColor:NSColor) {
        let offset = 4 * ((Int(self.width) * Int(p.y) + Int(p.x)))
        
        pixelBuffer[offset] = UInt8(normalizedColor.redComponent * 255.0)
        pixelBuffer[offset+1] = UInt8(normalizedColor.greenComponent * 255.0)
        pixelBuffer[offset+2] = UInt8(normalizedColor.blueComponent * 255.0)
        pixelBuffer[offset+3] = UInt8(normalizedColor.alphaComponent * 255.0)
    }
    
    func setColor(p:NSPoint, color color_:ConvertibleToNSColor) {
        
        let color = color_.color
        
        guard let normalizedColor = color.colorUsingColorSpaceName(NSCalibratedRGBColorSpace) else {
            print("-- cannot normalize color \(color)")
            return
        }
        
        let pixelBuffer = UnsafeMutablePointer<UInt8>(CGBitmapContextGetData(cgContext))
        
        _setColor(p, pixelBuffer:pixelBuffer, normalizedColor:normalizedColor)
    }
    
    subscript(x:Int, y:Int) -> ConvertibleToNSColor {
        
        get {
            let p = P(CGFloat(x),CGFloat(y))
            return color(p)
        }
        
        set {
            let p = P(CGFloat(x),CGFloat(y))
            setColor(p, color:newValue)
        }
    }
    
    func fill(p:NSPoint, color rawNewColor_:ConvertibleToNSColor) {
        // floodFillScanlineStack from http://lodev.org/cgtutor/floodfill.html
        
        let rawNewColor = rawNewColor_.color
        
        assert(p.x < width, "p.x \(p.x) out of range, must be < \(width)")
        assert(p.y < height, "p.y \(p.y) out of range, must be < \(height)")
        
        let pixelBuffer = UnsafeMutablePointer<UInt8>(CGBitmapContextGetData(cgContext))
        
        guard let newColor = rawNewColor.colorUsingColorSpaceName(NSCalibratedRGBColorSpace) else {
            print("-- cannot normalize color \(rawNewColor)")
            return
        }
        
        let oldColor = _color(p, pixelBuffer:pixelBuffer)
        
        if oldColor == newColor { return }
        
        // store rgba as [UInt8] to speed up comparisons
        var r : CGFloat = 0.0
        var g : CGFloat = 0.0
        var b : CGFloat = 0.0
        var a : CGFloat = 0.0
        
        oldColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgba = (UInt8(r*255),UInt8(g*255),UInt8(b*255),UInt8(a*255))
        
        var stack : [NSPoint] = [p]
        
        while let pp = stack.popLast() {
            
            var x1 = pp.x
            
            while(x1 >= 0 && _color(P(x1, pp.y), pixelBuffer:pixelBuffer) == oldColor) {
                x1--
            }
            
            x1++
            
            var spanAbove = false
            var spanBelow = false
            
            while(x1 < width && _colorIsEqual(P(x1, pp.y), pixelBuffer, rgba )) {
                
                _setColor(P(x1, pp.y), pixelBuffer:pixelBuffer, normalizedColor:newColor)
                
                let north = P(x1, pp.y-1)
                let south = P(x1, pp.y+1)
                
                if spanAbove == false && pp.y > 0 && _colorIsEqual(north, pixelBuffer, rgba) {
                    stack.append(north)
                    spanAbove = true
                } else if spanAbove && pp.y > 0 && !_colorIsEqual(north, pixelBuffer, rgba) {
                    spanAbove = false
                } else if spanBelow == false && pp.y < height - 1 && _colorIsEqual(south, pixelBuffer, rgba) {
                    stack.append(south)
                    spanBelow = true
                } else if spanBelow && pp.y < height - 1 && !_colorIsEqual(south, pixelBuffer, rgba) {
                    spanBelow = false
                }
                
                x1++
            }
        }
    }
    
    func line(p1:NSPoint, _ p2:NSPoint, _ color_:ConvertibleToNSColor? = NSColor.blackColor()) {
        
        let color = color_?.color
        
        context.saveGraphicsState()
        
        // align to the pixel grid
        CGContextTranslateCTM(cgContext, 0.5, 0.5)
        
        if let existingColor = color {
            CGContextSetStrokeColorWithColor(cgContext, existingColor.CGColor);
        }
        
        CGContextSetLineCap(cgContext, .Square)
        CGContextMoveToPoint(cgContext, p1.x, p1.y)
        CGContextAddLineToPoint(cgContext, p2.x, p2.y)
        CGContextStrokePath(cgContext)
        
        context.restoreGraphicsState()
    }
    
    func lineVertical(p1:NSPoint, height:CGFloat, _ color_:ConvertibleToNSColor? = nil) {
        let color = color_?.color
        let p2 = P(p1.x, p1.y + height - 1)
        self.line(p1, p2, color)
    }
    
    func lineHorizontal(p1:NSPoint, width:CGFloat, _ color_:ConvertibleToNSColor? = nil) {
        let color = color_?.color
        let p2 = P(p1.x + width - 1, p1.y)
        self.line(p1, p2, color)
    }
    
    func line(p1:NSPoint, deltaX:CGFloat, deltaY:CGFloat, _ color_:ConvertibleToNSColor? = nil) {
        let color = color_?.color
        let p2 = P(p1.x + deltaX, p1.y + deltaY)
        self.line(p1, p2, color)
    }
    
    func rectangle(rect:NSRect, stroke stroke_:ConvertibleToNSColor? = NSColor.blackColor(), fill fill_:ConvertibleToNSColor? = nil) {
        
        let stroke = stroke_?.color
        let fill = fill_?.color
        
        context.saveGraphicsState()
        
        // align to the pixel grid
        CGContextTranslateCTM(cgContext, 0.5, 0.5)
        
        if let existingFillColor = fill {
            existingFillColor.setFill()
            NSBezierPath.fillRect(rect)
        }
        
        if let existingStrokeColor = stroke {
            existingStrokeColor.setStroke()
            NSBezierPath.strokeRect(rect)
        }
        
        context.restoreGraphicsState()
    }
    
    func polygon(points:[NSPoint], stroke stroke_:ConvertibleToNSColor? = NSColor.blackColor(), lineWidth:CGFloat=1.0, fill fill_:ConvertibleToNSColor? = nil) {
        
        guard points.count >= 3 else {
            assertionFailure("at least 3 points are needed")
            return
        }
        
        context.saveGraphicsState()
        
        let path = NSBezierPath()
        
        path.moveToPoint(points[0])
        
        for i in 1...points.count-1 {
            path.lineToPoint(points[i])
        }
        
        if let existingFillColor = fill_?.color {
            existingFillColor.setFill()
            path.fill()
        }
        
        path.closePath()
        
        if let existingStrokeColor = stroke_?.color {
            existingStrokeColor.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
        
        context.restoreGraphicsState()
    }
    
    func ellipse(rect:NSRect, stroke stroke_:ConvertibleToNSColor? = NSColor.blackColor(), fill fill_:ConvertibleToNSColor? = nil) {
        
        let strokeColor = stroke_?.color
        let fillColor = fill_?.color
        
        context.saveGraphicsState()
        
        // align to the pixel grid
        CGContextTranslateCTM(cgContext, 0.5, 0.5)
        
        // fill
        if let existingFillColor = fillColor {
            existingFillColor.setFill()
            
            // reduce fillRect so that is doesn't cross the stoke
            let fillRect = R(rect.origin.x+1, rect.origin.y+1, rect.size.width-2, rect.size.height-2)
            CGContextFillEllipseInRect(cgContext, fillRect)
        }
        
        // stroke
        if let existingStrokeColor = strokeColor { existingStrokeColor.setStroke() }
        CGContextStrokeEllipseInRect(cgContext, rect)
        
        context.restoreGraphicsState()
    }
    
    private func degreesToRadians(x:CGFloat) -> CGFloat {
        return (M_PI * x / 180.0)
    }
    
    func save(path:String, open:Bool=false) -> Bool {
        guard let data = bitmapImageRep.representationUsingType(.NSPNGFileType, properties: [:]) else {
            print("\(__FILE__) \(__FUNCTION__) cannot get PNG data from bitmap")
            return false
        }
        let success = data.writeToFile(path, atomically: false)
        
        if open {
            NSWorkspace.sharedWorkspace().openFile(path)
        }
        
        return success
    }
    
    private func textWidth(text:NSString, font:NSFont) -> CGFloat {
        let maxSize : CGSize = CGSizeMake(CGFloat.max, font.pointSize)
        let textRect : CGRect = text.boundingRectWithSize(
            maxSize,
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: font],
            context: nil)
        return textRect.size.width
    }
    
    func image(fromPath path:String, _ p:NSPoint) {
        
        guard let data = NSData(contentsOfFile:path) else {
            print("\(__FILE__) \(__FUNCTION__) cannot read data at \(path)");
            return
        }
        
        guard let imgRep = NSBitmapImageRep(data: data) else {
            print("\(__FILE__) \(__FUNCTION__) cannot create bitmap image rep from data at \(path)");
            return
        }
        
        guard let cgImage = imgRep.CGImage else {
            print("\(__FILE__) \(__FUNCTION__) cannot get cgImage out of imageRep from \(path)");
            return
        }
        
        context.saveGraphicsState()
        
        CGContextScaleCTM(cgContext, 1.0, -1.0)
        CGContextTranslateCTM(cgContext, 0.0, -2.0 * p.y - imgRep.pixelsHigh)
        
        let rect = NSMakeRect(p.x, p.y, CGFloat(imgRep.pixelsWide), CGFloat(imgRep.pixelsHigh))
        
        CGContextDrawImage(cgContext, rect, cgImage)
        
        context.restoreGraphicsState()
    }
    
    func text(text:String, _ p:NSPoint, rotationRadians:CGFloat?, font : NSFont = NSFont(name: "Monaco", size: 10)!, color color_ : ConvertibleToNSColor = NSColor.blackColor()) {
        
        let color = color_.color
        
        let attr = [
            NSFontAttributeName:font,
            NSForegroundColorAttributeName:color
        ]
        
        context.saveGraphicsState()
        
        if let radians = rotationRadians {
            CGContextTranslateCTM(cgContext, p.x, p.y);
            CGContextRotateCTM(cgContext, radians)
            CGContextTranslateCTM(cgContext, -p.x, -p.y);
        }
        
        CGContextScaleCTM(cgContext, 1.0, -1.0)
        CGContextTranslateCTM(cgContext, 0.0, -2.0 * p.y - font.pointSize)
        
        text.drawAtPoint(p, withAttributes: attr)
        
        context.restoreGraphicsState()
    }
    
    func text(text:String, _ p:NSPoint, rotationDegrees degrees:CGFloat = 0.0, font : NSFont = NSFont(name: "Monaco", size: 10)!, color : ConvertibleToNSColor = NSColor.blackColor()) {
        self.text(text, p, rotationRadians: degreesToRadians(degrees), font: font, color: color)
    }
}
