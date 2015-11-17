//
//  Pattern.swift
//  PatternPicker
//
//  Created by Nate Parrott on 11/15/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

import UIKit

class Pattern: NSObject, NSCoding {
    init(type: PatternType, primaryColor: UIColor, secondaryColor: UIColor?) {
        self.type = type
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        super.init()
    }
    
    enum PatternType {
        case SolidColor
        case LinearGradient(endPoint: CGPoint)
        case RadialGradient
        case TonePattern(imageName: String)
        
        var involvesSecondaryColor: Bool {
            get {
                switch self {
                case .SolidColor: return false
                default: return true
                }
            }
        }
        
        var toDict: [String: AnyObject] {
            get {
                switch self {
                case .SolidColor: return ["type": "solid"]
                case .LinearGradient(endPoint: let endpoint): return ["type": "linear", "endPoint": NSStringFromCGPoint(endpoint)]
                case .RadialGradient: return ["type": "radial"]
                case .TonePattern(imageName: let imageName): return ["type": "tonePattern", "imageName": imageName]
                }
            }
        }
        
        static func fromDict(dict: [String: AnyObject]) -> PatternType! {
            switch dict["type"]! as! String {
                case "solid": return .SolidColor
                case "linear": return .LinearGradient(endPoint: CGPointFromString(dict["endPoint"]! as! String))
                case "radial": return .RadialGradient
                case "tonePattern": return .TonePattern(imageName: dict["imageName"]! as! String)
                default: return nil
            }
        }
    }
    
    class func allTypes() -> [PatternType] {
        return [.SolidColor, .LinearGradient(endPoint: CGPointMake(0, 1)), .LinearGradient(endPoint: CGPointMake(1, 1)), .RadialGradient, .TonePattern(imageName: "PPCheckerboardPattern"), .TonePattern(imageName: "PPStripedPattern"), .TonePattern(imageName: "PPPolkaDotPattern")]
    }
    
    class func solidColor(color: UIColor) -> Pattern {
        return Pattern(type: .SolidColor, primaryColor: color, secondaryColor: nil)
    }
    
    let primaryColor: UIColor
    let secondaryColor: UIColor?
    let type: PatternType
    
    var secondaryColorOrDefault: UIColor {
        if let s = secondaryColor {
            return s
        } else {
            let (h,s,v,a) = primaryColor.hsva
            return UIColor(hue: fmod(h + 0.3, 1.0), saturation: s, brightness: v, alpha: a)
        }
    }
    
    private class GradientView: UIView {
        override class func layerClass() -> AnyClass {
            return CAGradientLayer.self
        }
        var gradientLayer: CAGradientLayer {
            get {
                return self.layer as! CAGradientLayer
            }
        }
    }
    
    private class PlainView: UIView {
        
    }
    
    func renderAsView(prev: UIView?) -> UIView {
        switch type {
        case .SolidColor:
            let gradient = prev as? GradientView ?? GradientView()
            gradient.gradientLayer.locations = [0, 1]
            gradient.gradientLayer.colors = [primaryColor.CGColor, primaryColor.CGColor]
            return gradient
        case .LinearGradient(endPoint: _):
            let gradient = prev as? GradientView ?? GradientView()
            applyToGradientLayer(gradient.gradientLayer)
            return gradient
        case .RadialGradient:
            // TODO: gradient image caching?
            let imageView = prev as? UIImageView ?? UIImageView()
            imageView.image = getRadialGradientImage()
            return imageView
        case .TonePattern(imageName: _):
            // TODO: image caching
            let view = prev as? PlainView ?? PlainView()
            view.backgroundColor = UIColor(patternImage: getTonePatternImage())
            return view
        }
    }
    
    // MARK: Rendering
    func getRadialGradientImage() -> UIImage! {
        switch type {
        case .RadialGradient:
            let size = CGSizeMake(100, 100)
            UIGraphicsBeginImageContextWithOptions(size, true, 1)
            let secondary = secondaryColorOrDefault
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradientCreateWithColors(colorSpace, [primaryColor.CGColor, secondary.CGColor, secondary.CGColor], [0, 0.5, 1])
            let center = CGPointMake(size.width/2, size.height/2)
            CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), gradient, center
                , 0, center, size.height, [])
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        default:
            return nil
        }
    }
    func getTonePatternImage() -> UIImage! {
        switch type {
        case .TonePattern(imageName: let imageName):
            let image = UIImage(named: imageName)!
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            primaryColor.setFill()
            let rect = CGRectMake(0, 0, image.size.width, image.size.height)
            UIBezierPath(rect: rect).fill()
            CGContextClipToMask(UIGraphicsGetCurrentContext(), rect, image.CGImage)
            secondaryColorOrDefault.setFill()
            UIBezierPath(rect: rect).fill()
            let patternImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return patternImage
        default:
            return nil
        }
    }
    func applyToGradientLayer(layer: CAGradientLayer) {
        switch type {
        case .LinearGradient(endPoint: let endPoint):
            layer.locations = [0, 1]
            layer.colors = [primaryColor.CGColor, (secondaryColor ?? UIColor.clearColor()).CGColor]
            layer.startPoint = CGPointZero
            layer.endPoint = endPoint
        default: ()
        }
    }
    func applyToImageView(imageView: UIImageView) {
        switch type {
        case .RadialGradient:
            imageView.image = getRadialGradientImage()
            imageView.contentMode = .ScaleToFill
        default: ()
        }
    }
    
    // MARK: Coding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(primaryColor, forKey: "primaryColor")
        aCoder.encodeObject(secondaryColor, forKey: "secondaryColor")
        aCoder.encodeObject(type.toDict, forKey: "type")
    }
    
    required init?(coder aDecoder: NSCoder) {
        type = PatternType.fromDict(aDecoder.decodeObjectForKey("type") as! [String: AnyObject])
        primaryColor = aDecoder.decodeObjectForKey("primaryColor") as! UIColor
        secondaryColor = aDecoder.decodeObjectForKey("secondaryColor") as! UIColor?
    }
    
    // MARK: Client helpers
    var solidColorOrPattern: UIColor? {
        switch type {
        case .SolidColor:
            return primaryColor
        case .TonePattern(imageName: _):
            return UIColor(patternImage: getTonePatternImage())
        default: return nil
        }
    }
    var canApplyToGradientLayer: Bool {
        get {
            switch type {
            case .LinearGradient(endPoint: _): return true
            default: return false
            }
        }
    }
    var canApplyToImageView: Bool {
        get {
            switch type {
            case .RadialGradient: return true
            default: return false
            }
        }
    }
}

func ==(lhs: Pattern.PatternType, rhs: Pattern.PatternType) -> Bool {
    switch (lhs, rhs) {
    case (.SolidColor, .SolidColor): return true
    case (.LinearGradient(endPoint: let p1), .LinearGradient(endPoint: let p2)):
        return CGPointEqualToPoint(p1, p2)
    case (.RadialGradient, .RadialGradient): return true
    case (.TonePattern(imageName: let n1), .TonePattern(imageName: let n2)): return n1 == n2
    default: return false
    }
}
