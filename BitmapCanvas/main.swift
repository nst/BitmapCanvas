//
//  main.swift
//  BitmapCanvas
//
//  Created by nst on 28/02/16.
//  Copyright © 2016 Nicolas Seriot. All rights reserved.
//

import Foundation
import AppKit

func test() {
    
    var b = BitmapCanvas(640, 480)

    b[0,0] = NSColor.redColor()
    b[1,0] = NSColor.greenColor()
    b[2,0] = NSColor.blueColor()
    
    b.setAllowsAntialiasing(false)
    
    b.line(P(1,1), P(200,200))
    
    b.lineHorizontal(P(2,1), width: 100)
    b.lineHorizontal(P(1,3), width: 100, color:NSColor.cyanColor())
    b.lineHorizontal(P(1,5), width: 100)
    
    b.lineVertical(P(2,10), height: 100)
    
    b.rectangle(R(3, 3, 3, 3))
    
    b.rectangle(R(200, 200, 100, 50), strokeColor: NSColor.redColor())
    
    b.rectangle(R(300, 300, 100, 50), strokeColor: NSColor.redColor(), fillColor: Crayons["Aqua"])
    
    b.text("asd", P(250,250))
    b.text("asd", P(250,250), rotationRadians:CGFloat(-M_PI/2.0))
    b.text("asd", P(500,300), rotationDegrees:-90)
    
    b.line(P(400,350), P(450,450))
    b.lineHorizontal(P(100,100), width: 50)
    b.lineVertical(P(100,100), height: 50)
    
    b.setAllowsAntialiasing(true)
    
    CGContextAddEllipseInRect(b.cgContext, R(100, 100, 80, 50))
    CGContextStrokePath(b.cgContext)
    
    NSColor.orangeColor().setFill()
    
    let bp = NSBezierPath()
    bp.moveToPoint(P(70,30))
    bp.curveToPoint(P(100,70), controlPoint1: P(68,57), controlPoint2: P(75,76))
    bp.curveToPoint(P(157,66), controlPoint1: P(127,69), controlPoint2: P(127,97))
    bp.closePath()
    bp.fill()
    bp.stroke()
    
    b.image(fromPath:"/usr/share/httpd/icons/sphere2.png", P(20,20))
    
    b.setAllowsAntialiasing(false)
    
    b.rectangle(R(3,3,3,3), strokeColor:NSColor.blueColor())
    
    b[0,0] = NSColor.cyanColor()

    b[1,1] = NSColor.redColor()
    b[2,2] = NSColor.greenColor()
    b[3,3] = NSColor.yellowColor()
    
    b.setAllowsAntialiasing(true)
    
    b[6,1] = NSColor.redColor()
    b[7,2] = NSColor.greenColor()
    b[8,3] = NSColor.yellowColor()
    
    b.rectangle(R(8,3,3,3), strokeColor:NSColor.blueColor())
    
    let path = "/tmp/test.png"
    
    b.save(path)
    
    NSWorkspace.sharedWorkspace().openFile(path)
}

func bitmap() {
    // let b = BitmapCanvas(32, 32)
    
    let color = NSColor(deviceWhite: 0.95, alpha: 1.0)
    let b = BitmapCanvas(32, 32, backgroundColor: color)
    
    b.save("/tmp/bitmap.png")
}

func points() {
    
    let color = NSColor(deviceWhite: 0.95, alpha: 1.0).colorUsingColorSpaceName(NSDeviceRGBColorSpace)
    var b = BitmapCanvas(32, 32, backgroundColor: color)
    
    b[1,1] = NSColor.blackColor()

    b[1,3] = NSColor.redColor()
    b[2,3] = NSColor.greenColor()
    b[3,3] = NSColor.blueColor()
    
    b.save("/tmp/bitmap_points.png")
}

func lines() {
    
    let color = NSColor(deviceWhite: 0.95, alpha: 1.0)
    let b = BitmapCanvas(32, 32, backgroundColor: color)
    
    b.line(P(1,1), P(10,10))
    
    b.line(P(1,10), P(10,19), color: NSColor.redColor())
    b.lineHorizontal(P(1,21), width: 20)
    b.lineVertical(P(20, 1), height: 19, color: NSColor.blueColor())
    
    b.save("/tmp/bitmap_lines.png")
}

func rects() {
    
    let color = NSColor(deviceWhite: 0.95, alpha: 1.0)
    let b = BitmapCanvas(32, 32, backgroundColor: color)
    
    b.rectangle(R(5,5,20,10))
    
    b.rectangle(R(10,10,20,10), strokeColor: NSColor.blueColor(), fillColor: NSColor.magentaColor())
    
    b.save("/tmp/bitmap_rects.png")
}

func text() {
    
    let color = NSColor(deviceWhite: 0.95, alpha: 1.0)
    let b = BitmapCanvas(32, 32, backgroundColor: color)
    
    b.text("hi", P(5,10))
    
    b.text("hello", P(20,30),
        rotationDegrees: -90,
        font: NSFont(name: "Helvetica", size: 10)!,
        color: NSColor.redColor())
    
    b.save("/tmp/bitmap_text.png")
}

func image() {
    
    let color = NSColor(deviceWhite: 0.95, alpha: 1.0)
    let b = BitmapCanvas(32, 32, backgroundColor: color)
    
    b.image(fromPath:"/usr/share/httpd/icons/sphere2.png", P(0,0))
    
    b.save("/tmp/bitmap_image.png")
}

func bezier() {
    
    let color = NSColor(deviceWhite: 0.95, alpha: 1.0)
    let b = BitmapCanvas(32, 32, backgroundColor: color)
    
    b.setAllowsAntialiasing(true)
    
    NSColor.orangeColor().setFill()
    
    let bp = NSBezierPath()
    bp.moveToPoint(P(2,2))
    bp.curveToPoint(P(20,14), controlPoint1: P(14,30), controlPoint2: P(15,30))
    bp.curveToPoint(P(32,13), controlPoint1: P(24,14), controlPoint2: P(24,19))
    bp.closePath()
    bp.fill()
    bp.stroke()
    
    b.save("/tmp/bitmap_bezier.png")
}

func cgContext() {
    
    let color = NSColor(deviceWhite: 0.95, alpha: 1.0)
    let b = BitmapCanvas(32, 32, backgroundColor: color)
    
    CGContextAddEllipseInRect(b.cgContext, R(2, 2, 24, 24))
    CGContextStrokePath(b.cgContext)
    
    b.setAllowsAntialiasing(true)
    
    CGContextSetStrokeColorWithColor(b.cgContext, NSColor.blueColor().CGColor)
    CGContextAddEllipseInRect(b.cgContext, R(12, 12, 24, 24))
    CGContextStrokePath(b.cgContext)
    
    b.save("/tmp/bitmap_cgcontext.png")
}

test()

bitmap()
points()
lines()
rects()
text()
image()
bezier()
cgContext()
