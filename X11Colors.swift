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
        let matches = regex.matchesInString(s, options: [], range: NSMakeRange(0, s.characters.count))
        
        var results : [String] = []
        
        for m in matches {
            for i in 1..<m.numberOfRanges {
                let range = m.rangeAtIndex(i)
                results.append((s as NSString).substringWithRange(range))
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
        
        let scanner = NSScanner(string: self)

        if scanner.scanString("#", intoString: nil) {
            var result : UInt32 = 0
            if scanner.scanHexInt(&result) {
                return result.color
            } else {
                assertionFailure("cannot convert \(self) to hex color)")
                return NSColor.clearColor()
            }
        }
        
        if let c = X11Colors.sharedInstance.colorList.colorWithKey(self.lowercaseString) {
            return c
        }
        
        assertionFailure("cannot convert \(self) into color)")
        return NSColor.clearColor()
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
    
}

func C(r:Int, _ g:Int, _ b:Int, _ a:Int = 255) -> NSColor {
    return NSColor(r,g,b,a)
}

func C(r:CGFloat, _ g:CGFloat, _ b:CGFloat, _ a:CGFloat = 255.0) -> NSColor {
    return NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
}

struct X11Colors {

    static let sharedInstance = X11Colors(namePrettifier: { $0.lowercaseString })
    
    var colorList = NSColorList(name: "X11")
    
    init(path:String = "/opt/X11/share/X11/rgb.txt", namePrettifier:(original:String) -> (String)) {
        
        let contents = try! String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
        
        contents.enumerateLines({ (line, stop) -> () in
            
            let pattern = "\\s?+(\\d+?)\\s+(\\d+?)\\s+(\\d+?)\\s+(\\w+)$"
            let matches = try! NSRegularExpression.findAll(string: line, pattern: pattern)
            if matches.count != 4 { return } // ignore names with white spaces, they also appear in camel case
            
            let r = CGFloat(Int(matches[0])!)
            let g = CGFloat(Int(matches[1])!)
            let b = CGFloat(Int(matches[2])!)
            
            let name = matches[3]
            
            let prettyName = namePrettifier(original:name)
            
            let color = NSColor(calibratedRed: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
            self.colorList.setColor(color, forKey: prettyName)
            
            //print("\(name) \t -> \t \(prettyName)")
        })
    }
    
    static func dump(inPath:String, outPath:String) -> Bool {
        
        let x11Colors = X11Colors(namePrettifier: {
            let name = ($0 as NSString)
            let firstCharacter = name.substringToIndex(1)
            let restOfString = name.substringWithRange(NSMakeRange(1, name.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)-1))
            return "\(firstCharacter.uppercaseString)\(restOfString)"
        })
        
        return x11Colors.colorList.writeToFile(outPath)
    }
}
