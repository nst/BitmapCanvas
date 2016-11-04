//
//  X11ColorList.swift
//  BitmapCanvas
//
//  Created by nst on 28/02/16.
//  Copyright © 2016 Nicolas Seriot. All rights reserved.
//

import Cocoa

extension NSRegularExpression {
    class func findAll(string s: String, pattern: String) throws -> [String] {
        
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: s, options: [], range: NSMakeRange(0, s.characters.count))
        
        var results : [String] = []
        
        for m in matches {
            for i in 1..<m.numberOfRanges {
                let range = m.rangeAt(i)
                results.append((s as NSString).substring(with: range))
            }
        }
        
        return results
    }
}

protocol ConvertibleToNSColor {
    var color : NSColor { get }
}

extension NSColor : ConvertibleToNSColor {
    var color : NSColor {
        return self
    }
}

extension UInt32 : ConvertibleToNSColor {
    
    var color : NSColor {
        
        let r = CGFloat((self >> 16) & 0xff) / 255
        let g = CGFloat((self >> 08) & 0xff) / 255
        let b = CGFloat((self >> 00) & 0xff) / 255
        
        return NSColor(calibratedRed:r, green:g, blue:b, alpha:1.0)
    }
}

extension String : ConvertibleToNSColor {
    
    var color : NSColor {
        
        let scanner = Scanner(string: self)

        if scanner.scanString("#", into: nil) {
            var result : UInt32 = 0
            if scanner.scanHexInt32(&result) {
                return result.color
            } else {
                assertionFailure("cannot convert \(self) to hex color)")
                return NSColor.clear
            }
        }
        
        if let c = X11Colors.sharedInstance.colorList.color(withKey: self.lowercased()) {
            return c
        }
        
        assertionFailure("cannot convert \(self) into color)")
        return NSColor.clear
    }
}

extension NSColor {
    
    convenience init(_ r:Int, _ g:Int, _ b:Int, _ a:Int = 255) {
        self.init(
            calibratedRed: CGFloat(r)/255.0,
            green: CGFloat(g)/255.0,
            blue: CGFloat(b)/255.0,
            alpha: CGFloat(a)/255.0)
    }
    
    class var randomColor : NSColor {
        return C(Int(arc4random_uniform(256)), Int(arc4random_uniform(256)), Int(arc4random_uniform(256)))
    }
}

func C(_ r:Int, _ g:Int, _ b:Int, _ a:Int = 255) -> NSColor {
    return NSColor(r,g,b,a)
}

func C(_ r:CGFloat, _ g:CGFloat, _ b:CGFloat, _ a:CGFloat = 255.0) -> NSColor {
    return NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
}

class X11Colors {

    static let sharedInstance = X11Colors(namePrettifier: { $0.lowercased() })
    
    var colorList = NSColorList(name: "X11")
    
    init(path:String = "/opt/X11/share/X11/rgb.txt", namePrettifier:@escaping (_ original:String) -> (String)) {
        
        let contents = try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
        
        contents.enumerateLines { (line, stop) in
            
            let pattern = "\\s?+(\\d+?)\\s+(\\d+?)\\s+(\\d+?)\\s+(\\w+)$"
            let matches = try! NSRegularExpression.findAll(string: line, pattern: pattern)
            if matches.count != 4 { return } // ignore names with white spaces, they also appear in camel case
            
            let r = CGFloat(Int(matches[0])!)
            let g = CGFloat(Int(matches[1])!)
            let b = CGFloat(Int(matches[2])!)
            
            let name = matches[3]
            
            let prettyName = namePrettifier(name)
            
            let color = NSColor(calibratedRed: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
            self.colorList.setColor(color, forKey: prettyName)
            
            //print("\(name) \t -> \t \(prettyName)")
        }
    }
    
    static func dump(_ inPath:String, outPath:String) -> Bool {
        
        let x11Colors = X11Colors(namePrettifier: {
            let name = ($0 as NSString)
            let firstCharacter = name.substring(to: 1)
            let restOfString = name.substring(with: NSMakeRange(1, name.lengthOfBytes(using: String.Encoding.utf8.rawValue)-1))
            return "\(firstCharacter.uppercased())\(restOfString)"
        })
        
        return x11Colors.colorList.write(toFile: outPath)
    }
}
