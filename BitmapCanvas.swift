//
//  main.swift
//  BitmapCanvas
//
//  Created by nst on 04/01/16.
//  Copyright © 2016 Nicolas Seriot. All rights reserved.
//

import Cocoa

infix operator * : MultiplicationPrecedence

func *(left:CGFloat, right:Int) -> CGFloat
{ return left * CGFloat(right) }

func *(left:Int, right:CGFloat) -> CGFloat
{ return CGFloat(left) * right }

func *(left:CGFloat, right:Double) -> CGFloat
{ return left * CGFloat(right) }

func *(left:Double, right:CGFloat) -> CGFloat
{ return CGFloat(left) * right }

infix operator + : AdditionPrecedence

func +(left:CGFloat, right:Int) -> CGFloat
{ return left + CGFloat(right) }

func +(left:Int, right:CGFloat) -> CGFloat
{ return CGFloat(left) + right }

func +(left:CGFloat, right:Double) -> CGFloat
{ return left + CGFloat(right) }

func +(left:Double, right:CGFloat) -> CGFloat
{ return CGFloat(left) + right }

infix operator - : AdditionPrecedence

func -(left:CGFloat, right:Int) -> CGFloat
{ return left - CGFloat(right) }

func -(left:Int, right:CGFloat) -> CGFloat
{ return CGFloat(left) - right }

func -(left:CGFloat, right:Double) -> CGFloat
{ return left - CGFloat(right) }

func -(left:Double, right:CGFloat) -> CGFloat
{ return CGFloat(left) - right }

//

func P(_ x:CGFloat, _ y:CGFloat) -> NSPoint {
    return NSMakePoint(x, y)
}

func P(_ x:Int, _ y:Int) -> NSPoint {
    return NSMakePoint(CGFloat(x), CGFloat(y))
}

func RandomPoint(maxX:Int, maxY:Int) -> NSPoint {
    return P(CGFloat(arc4random_uniform((UInt32(maxX+1)))), CGFloat(arc4random_uniform((UInt32(maxY+1)))))
}

func R(_ x:CGFloat, _ y:CGFloat, _ w:CGFloat, _ h:CGFloat) -> NSRect {
    return NSMakeRect(x, y, w, h)
}

func R(_ x:Int, _ y:Int, _ w:Int, _ h:Int) -> NSRect {
    return NSMakeRect(CGFloat(x), CGFloat(y), CGFloat(w), CGFloat(h))
}

class BitmapCanvas {
    
    let bitmapImageRep : NSBitmapImageRep
    let context : NSGraphicsContext
    
    var cgContext : CGContext {
        return context.cgContext
    }
    
    var width : CGFloat {
        return bitmapImageRep.size.width
    }
    
    var height : CGFloat {
        return bitmapImageRep.size.height
    }
    
    func setAllowsAntialiasing(_ antialiasing : Bool) {
        cgContext.setAllowsAntialiasing(antialiasing)
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
        
        NSGraphicsContext.setCurrent(context)
        
        setAllowsAntialiasing(false)
        
        if let b = background {
            
            let rect = NSMakeRect(0, 0, CGFloat(width), CGFloat(height))
            
            context.saveGraphicsState()
            
            b.color.setFill()
            NSBezierPath.fill(rect)
            
            context.restoreGraphicsState()
        }
        
        // makes coordinates start upper left
        cgContext.translateBy(x: 0, y: CGFloat(height))
        cgContext.scaleBy(x: 1.0, y: -1.0)
    }
    
    fileprivate func _colorIsEqual(_ p:NSPoint, _ pixelBuffer:UnsafePointer<UInt8>, _ rgba:(UInt8,UInt8,UInt8,UInt8)) -> Bool {
        
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
    
    fileprivate func _color(_ p:NSPoint, pixelBuffer:UnsafePointer<UInt8>) -> NSColor {
        
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
    
    func color(_ p:NSPoint) -> NSColor {
        
        guard let data = cgContext.data else { assertionFailure(); return NSColor.clear }
        
        let pixelBuffer = data.assumingMemoryBound(to: UInt8.self)
        
        return _color(p, pixelBuffer:pixelBuffer)
    }
    
    fileprivate func _setColor(_ p:NSPoint, pixelBuffer:UnsafeMutablePointer<UInt8>, normalizedColor:NSColor) {
        let offset = 4 * ((Int(self.width) * Int(p.y) + Int(p.x)))
        
        pixelBuffer[offset] = UInt8(normalizedColor.redComponent * 255.0)
        pixelBuffer[offset+1] = UInt8(normalizedColor.greenComponent * 255.0)
        pixelBuffer[offset+2] = UInt8(normalizedColor.blueComponent * 255.0)
        pixelBuffer[offset+3] = UInt8(normalizedColor.alphaComponent * 255.0)
    }
    
    func setColor(_ p:NSPoint, color color_:ConvertibleToNSColor) {
        
        let color = color_.color
        
        guard let normalizedColor = color.usingColorSpaceName(NSCalibratedRGBColorSpace) else {
            print("-- cannot normalize color \(color)")
            return
        }
        
        guard let data = cgContext.data else { assertionFailure(); return }

        let pixelBuffer = data.assumingMemoryBound(to: UInt8.self)
        
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
    
    func fill(_ p:NSPoint, color rawNewColor_:ConvertibleToNSColor) {
        // floodFillScanlineStack from http://lodev.org/cgtutor/floodfill.html
        
        let rawNewColor = rawNewColor_.color
        
        assert(p.x < width, "p.x \(p.x) out of range, must be < \(width)")
        assert(p.y < height, "p.y \(p.y) out of range, must be < \(height)")
        
        guard let data = cgContext.data else { assertionFailure(); return }

        let pixelBuffer = data.assumingMemoryBound(to: UInt8.self)
        
        guard let newColor = rawNewColor.usingColorSpaceName(NSCalibratedRGBColorSpace) else {
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
                x1 -= 1
            }
            
            x1 += 1
            
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
                
                x1 += 1
            }
        }
    }
    
    func line(_ p1:NSPoint, _ p2:NSPoint, _ color_:ConvertibleToNSColor? = NSColor.black) {
        
        let color = color_?.color
        
        context.saveGraphicsState()
        
        // align to the pixel grid
        cgContext.translateBy(x: 0.5, y: 0.5)
        
        if let existingColor = color {
            cgContext.setStrokeColor(existingColor.cgColor);
        }
        
        cgContext.setLineCap(.square)
        cgContext.move(to: CGPoint(x: p1.x, y: p1.y))
        cgContext.addLine(to: CGPoint(x: p2.x, y: p2.y))
        cgContext.strokePath()
        
        context.restoreGraphicsState()
    }

    func line(_ p1:NSPoint, length:CGFloat = 1.0, degreesCW:CGFloat = 0.0, _ color_:ConvertibleToNSColor? = NSColor.black) -> NSPoint {
        let color = color_?.color
        let radians = degreesToRadians(degreesCW)
        let p2 = P(p1.x + sin(radians) * length, p1.y - cos(radians) * length)
        self.line(p1, p2, color)
        return p2
    }

    func lineVertical(_ p1:NSPoint, height:CGFloat, _ color_:ConvertibleToNSColor? = nil) {
        let color = color_?.color
        let p2 = P(p1.x, p1.y + height - 1)
        self.line(p1, p2, color)
    }
    
    func lineHorizontal(_ p1:NSPoint, width:CGFloat, _ color_:ConvertibleToNSColor? = nil) {
        let color = color_?.color
        let p2 = P(p1.x + width - 1, p1.y)
        self.line(p1, p2, color)
    }
    
    func line(_ p1:NSPoint, deltaX:CGFloat, deltaY:CGFloat, _ color_:ConvertibleToNSColor? = nil) {
        let color = color_?.color
        let p2 = P(p1.x + deltaX, p1.y + deltaY)
        self.line(p1, p2, color)
    }
    
    func rectangle(_ rect:NSRect, stroke stroke_:ConvertibleToNSColor? = NSColor.black, fill fill_:ConvertibleToNSColor? = nil) {
        
        let stroke = stroke_?.color
        let fill = fill_?.color
        
        context.saveGraphicsState()
        
        // align to the pixel grid
        cgContext.translateBy(x: 0.5, y: 0.5)
        
        if let existingFillColor = fill {
            existingFillColor.setFill()
            NSBezierPath.fill(rect)
        }
        
        if let existingStrokeColor = stroke {
            existingStrokeColor.setStroke()
            NSBezierPath.stroke(rect)
        }
        
        context.restoreGraphicsState()
    }
    
    func polygon(_ points:[NSPoint], stroke stroke_:ConvertibleToNSColor? = NSColor.black, lineWidth:CGFloat=1.0, fill fill_:ConvertibleToNSColor? = nil) {
        
        guard points.count >= 3 else {
            assertionFailure("at least 3 points are needed")
            return
        }
        
        context.saveGraphicsState()
        
        let path = NSBezierPath()
        
        path.move(to: points[0])
        
        for i in 1...points.count-1 {
            path.line(to: points[i])
        }
        
        if let existingFillColor = fill_?.color {
            existingFillColor.setFill()
            path.fill()
        }
        
        path.close()
        
        if let existingStrokeColor = stroke_?.color {
            existingStrokeColor.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
        
        context.restoreGraphicsState()
    }
    
    func ellipse(_ rect:NSRect, stroke stroke_:ConvertibleToNSColor? = NSColor.black, fill fill_:ConvertibleToNSColor? = nil) {
        
        let strokeColor = stroke_?.color
        let fillColor = fill_?.color
        
        context.saveGraphicsState()
        
        // align to the pixel grid
        cgContext.translateBy(x: 0.5, y: 0.5)
        
        // fill
        if let existingFillColor = fillColor {
            existingFillColor.setFill()
            
            // reduce fillRect so that is doesn't cross the stoke
            let fillRect = R(rect.origin.x+1, rect.origin.y+1, rect.size.width-2, rect.size.height-2)
            cgContext.fillEllipse(in: fillRect)
        }
        
        // stroke
        if let existingStrokeColor = strokeColor { existingStrokeColor.setStroke() }
        cgContext.strokeEllipse(in: rect)
        
        context.restoreGraphicsState()
    }
    
    fileprivate func degreesToRadians(_ x:CGFloat) -> CGFloat {
        return (M_PI * x / 180.0)
    }
    
    func save(_ path:String, open:Bool=false) {
        guard let data = bitmapImageRep.representation(using: .PNG, properties: [:]) else {
            print("\(#file) \(#function) cannot get PNG data from bitmap")
            return
        }
        
        do {
            try data.write(to: URL(fileURLWithPath: path), options: [])
            if open {
                NSWorkspace.shared().openFile(path)
            }
        } catch let e {
            print(e)
        }
    }
    
    static func textWidth(_ text:NSString, font:NSFont) -> CGFloat {
        let maxSize : CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: font.pointSize)
        let textRect : CGRect = text.boundingRect(
            with: maxSize,
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: font],
            context: nil)
        return textRect.size.width
    }
    
    func image(fromPath path:String, _ p:NSPoint) {
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("\(#file) \(#function) cannot read data at \(path)");
            return
        }
        
        guard let imgRep = NSBitmapImageRep(data: data) else {
            print("\(#file) \(#function) cannot create bitmap image rep from data at \(path)");
            return
        }
        
        guard let cgImage = imgRep.cgImage else {
            print("\(#file) \(#function) cannot get cgImage out of imageRep from \(path)");
            return
        }
        
        context.saveGraphicsState()
        
        cgContext.scaleBy(x: 1.0, y: -1.0)
        cgContext.translateBy(x: 0.0, y: -2.0 * p.y - imgRep.pixelsHigh)
        
        let rect = NSMakeRect(p.x, p.y, CGFloat(imgRep.pixelsWide), CGFloat(imgRep.pixelsHigh))
        
        cgContext.draw(cgImage, in: rect)
        
        context.restoreGraphicsState()
    }
    
    func text(_ text:String, _ p:NSPoint, rotationRadians:CGFloat?, font : NSFont = NSFont(name: "Monaco", size: 10)!, color color_ : ConvertibleToNSColor = NSColor.black) {
        
        let color = color_.color
        
        let attr = [
            NSFontAttributeName:font,
            NSForegroundColorAttributeName:color
        ]
        
        context.saveGraphicsState()
        
        if let radians = rotationRadians {
            cgContext.translateBy(x: p.x, y: p.y);
            cgContext.rotate(by: radians)
            cgContext.translateBy(x: -p.x, y: -p.y);
        }
        
        cgContext.scaleBy(x: 1.0, y: -1.0)
        cgContext.translateBy(x: 0.0, y: -2.0 * p.y - font.pointSize)
        
        text.draw(at: p, withAttributes: attr)
        
        context.restoreGraphicsState()
    }
    
    func text(_ text:String, _ p:NSPoint, rotationDegrees degrees:CGFloat = 0.0, font : NSFont = NSFont(name: "Monaco", size: 10)!, color : ConvertibleToNSColor = NSColor.black) {
        self.text(text, p, rotationRadians: degreesToRadians(degrees), font: font, color: color)
    }
}
