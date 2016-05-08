//
//  main.swift
//  BitmapCanvas
//
//  Created by nst on 28/02/16.
//  Copyright © 2016 Nicolas Seriot. All rights reserved.
//

import Foundation
import AppKit

let PROJECT_PATH = "/Users/nst/Projects/BitmapCanvas"

func switzerland() {
    
    guard let resultsData = NSData(contentsOfFile: PROJECT_PATH+"/files/results.json") else { return }
    guard let optResults = try? NSJSONSerialization.JSONObjectWithData(resultsData, options: []) as? [String:AnyObject] else { return }
    guard let results = optResults else { return }
    
    guard let switzerlandData = NSData(contentsOfFile: PROJECT_PATH+"/files/switzerland.json") else { return }
    guard let optSwitzerland = try? NSJSONSerialization.JSONObjectWithData(switzerlandData, options: []) as? [String:AnyObject] else { return }
    guard let switzerland = optSwitzerland else { return }
    
    let b = BitmapCanvas(365, 235, "white")
    
    b.image(fromPath: PROJECT_PATH+"/files/switzerland.gif", P(0,0))
    
    b.text("2016-02-28 \"Pas de spéculation sur les denrées alimentaires\"", P(5,220))
    
    let values : [Double] = results.flatMap { (k,v) in v as? Double }
    
    let positiveValues = values.filter { $0 >= 50.0 }
    let negativeValues = values.filter { $0 < 50.0 }
    
    let minPositive = positiveValues.minElement() ?? 0.0
    let maxPositive = positiveValues.maxElement() ?? 0.01
    
    let minNegative = negativeValues.minElement() ?? 0.0
    let maxNegative = negativeValues.maxElement() ?? 0.01
    
    let positiveRange = maxPositive - minPositive
    let negativeRange = maxNegative - minNegative
    
    print(minPositive, maxPositive)
    print(minNegative, maxNegative)
    
    for (k, cantonDict) in switzerland {
        
        guard let labelPoint = cantonDict["label"] as? [Int] else { continue }
        
        // fill color
        
        var fillColor = NSColor.lightGrayColor()
        if let percent = results[k] as? Double {
            if percent < 50.0 {
                let i = ((percent - minNegative) / negativeRange) - 0.15
                fillColor = NSColor(calibratedRed: 1.0, green: CGFloat(i), blue: CGFloat(i), alpha: 1.0)
            } else {
                let i = (1.0 - (percent - minPositive) / positiveRange) - 0.15
                fillColor = NSColor(calibratedRed: CGFloat(i), green: 1.0, blue: CGFloat(i), alpha: 1.0)
            }
        }
        
        // fill cantons
        
        let fillPoints = cantonDict["fill"] as? [[Int]] ?? [labelPoint]
        
        for pts in fillPoints {
            let p = P(pts[0], pts[1])
            b.fill(p, color: fillColor)
        }
        
        // draw labels

        let p = P(labelPoint[0], labelPoint[1])
        b.text(k, p)
    }
    
    let path = "/tmp/out.png"
    
    b.save(path, open:true)
}

func bitmap() {
    
    let b = BitmapCanvas(32, 32, "PapayaWhip")
    
    b.save("/tmp/bitmap.png")
}

func points() {
    
    let b = BitmapCanvas(32, 32, "PapayaWhip")
    
    b[1,1] = NSColor.blackColor()
    
    b[1,3] = "red"
    b[2,3] = "#00FF00"
    b[3,3] = NSColor.blueColor()
    
    b.save("/tmp/points.png")
}

func lines() {
    
    let b = BitmapCanvas(32, 32, "PapayaWhip")
    
    b.line(P(1,1), P(10,10))
    
    b.line(P(1,10), P(10,19), "red")
    b.lineHorizontal(P(1,21), width:20)
    b.lineVertical(P(20, 1), height:19, "blue")
    
    b.save("/tmp/lines.png")
}

func rects() {
    
    let b = BitmapCanvas(32, 32, "PapayaWhip")
    
    b.rectangle(R(5,5,20,10))
    
    b.rectangle(R(10,10,20,10), stroke:"blue", fill:"magenta")
    
    b.save("/tmp/rects.png")
}

func ellipse() {
    
    let b = BitmapCanvas(32, 32, "PapayaWhip")
    
    b.ellipse(R(5,5,20,10))
    
    b.ellipse(R(10,10,18,21), stroke:"blue", fill:"magenta")
    
    b.save("/tmp/ellipse.png", open:true)
}

func text() {
    
    let b = BitmapCanvas(32, 32, "PapayaWhip")

    b.text("hi", P(5,10))

    b.text("hello", P(20,30),
        rotationDegrees: -90,
        font: NSFont(name: "Helvetica", size: 10)!,
        color: NSColor.redColor())
    
    b.save("/tmp/text.png")
}

func image() {
    
    let b = BitmapCanvas(32, 32, "PapayaWhip")
    
    b.image(fromPath:"/usr/share/httpd/icons/sphere2.png", P(0,0))
    
    b.save("/tmp/image.png", open:true)
}

func polygon() {
    
    let b = BitmapCanvas(32, 32, "PapayaWhip")
    
    b.setAllowsAntialiasing(true)
    
    let points = [P(3,3), P(28,5), P(25,22), P(12,18)]
    
    b.polygon(points, stroke:"blue", fill:"SkyBlue")
    
    b.save("/tmp/polygon.png", open:true)
}

func bezier() {
    
    let b = BitmapCanvas(32, 32, "PapayaWhip")
    
    b.setAllowsAntialiasing(true)
    
    NSColor.orangeColor().setFill()
    
    let bp = NSBezierPath()
    bp.moveToPoint(P(2,2))
    bp.curveToPoint(P(20,14), controlPoint1: P(14,30), controlPoint2: P(15,30))
    bp.curveToPoint(P(32,13), controlPoint1: P(24,14), controlPoint2: P(24,19))
    bp.closePath()
    bp.fill()
    bp.stroke()
    
    b.save("/tmp/bezier.png")
}

func cgContext() {
    
    let b = BitmapCanvas(32, 32, "PapayaWhip")
    
    CGContextAddEllipseInRect(b.cgContext, R(2, 2, 24, 24))
    CGContextStrokePath(b.cgContext)
    
    b.setAllowsAntialiasing(true)
    
    CGContextSetStrokeColorWithColor(b.cgContext, NSColor.blueColor().CGColor)
    CGContextAddEllipseInRect(b.cgContext, R(12, 12, 24, 24))
    CGContextStrokePath(b.cgContext)
    
    b.save("/tmp/cgcontext.png")
}

func gradient() {

    let (w, h) = (255, 255)

    let b = BitmapCanvas(w, h)
    for i in 0..<w {
        for j in 0..<h {
            b[i,j] = NSColor(i,j,100)
        }
    }

    b.save("/tmp/gradient.png", open:true)
}

func voronoi() {
    
    let w = 255
    let h = 255
    let n = 25
    
    let b = BitmapCanvas(w, h)
    
    var pointsColors : [(NSPoint, NSColor)] = []
    
    for _ in 0...n {
        let p = RandomPoint(maxX: w, maxY: h)
        let c = NSColor.randomColor()
        pointsColors.append((p,c))
    }
    
    for x in 0..<w {
        for y in 0..<h {
            let distances = pointsColors.map { hypot($0.0.x - x, $0.0.y - y) }
            b[x,y] = pointsColors[distances.indexOf(distances.minElement()!)!].1
        }
    }
    
    for (p,_) in pointsColors {
        let rect = R(p.x-1, p.y-1, 3, 3)
        b.ellipse(rect, stroke:"black", fill:"black")
    }
    
    b.save("/tmp/voronoi.png", open:true)
}

switzerland()

bitmap()
points()
lines()
rects()
ellipse()
text()
image()
bezier()
cgContext()
polygon()

gradient()
voronoi()

//let b = BitmapCanvas(6000,6000, "SkyBlue")
//b.fill(P(270,243), color: NSColor.blueColor())
//b.save("/tmp/out.png", open: true)

//X11Colors.dump("/opt/X11/share/X11/rgb.txt", outPath:"/tmp/X11.clr")
