//
//  PatternPickerView.swift
//  PatternPicker
//
//  Created by Nate Parrott on 11/15/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

import UIKit

class PatternPickerView: UIView {
    var pattern = Pattern(type: .SolidColor, primaryColor: UIColor.greenColor(), secondaryColor: nil) {
        didSet {
            if onlyAllowSolidColors && !(pattern.type == Pattern.PatternType.SolidColor) {
                pattern = Pattern(type: .SolidColor, primaryColor: pattern.primaryColor, secondaryColor: nil)
            } else {
                cell.hue = Float(pattern.primaryColor.hsva.0)
                cell.preview.pattern = pattern
            }
        }
    }
    var onlyAllowSolidColors = false
    var onPatternChanged: (Pattern -> ())?
    var onPatternChangeTransactionEnded: (() -> ())?
    var shouldEditModally: (() -> ())?
    private func _updatePattern(pattern: Pattern) {
        self.pattern = pattern
        if let cb = onPatternChanged {
            cb(pattern)
        }
    }
    
    static let rounding: CGFloat = 4
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    let cell = ColorCell()
    
    func setup() {
        addSubview(cell)
        let p = self.pattern
        self.pattern = p
        
        cell.onHueChanged = {
            [weak self]
            (hue) in
            if let p = self {
                var (_, s, v, a) = p.pattern.primaryColor.hsva
                if s == 0 {
                    s = 1
                }
                if v == 0 {
                    v = 1
                }
                if a == 0 {
                    a = 1
                }
                let newPrimaryColor = UIColor(hue: CGFloat(hue), saturation: s, brightness: v, alpha: a)
                let pattern = Pattern(type: p.pattern.type, primaryColor: newPrimaryColor, secondaryColor: p.pattern.secondaryColor)
                p._updatePattern(pattern)
            }
        }
        
        cell.onTouchUp = {
            [weak self] in
            if let cb = self!.onPatternChangeTransactionEnded {
                cb()
            }
        }
        
        cell.label.text = NSLocalizedString("Fill", comment: "")
        cell.rightButton.setImage(UIImage(named: "PPChevron")!, forState: .Normal)
        cell.rightButton.addTarget(self, action: "_shouldEditModally:", forControlEvents: .TouchUpInside)
        
        clipsToBounds = true
        layer.cornerRadius = PatternPickerView.rounding
    }
    
    func _shouldEditModally(sender: UIButton) {
        if let fn = shouldEditModally {
            fn()
        }
    }
    
    func editModally(viewController: UIViewController) {
        let vc = PatternPickerViewController()
        vc.onlyAllowSolidColors = onlyAllowSolidColors
        vc.pattern = pattern
        vc.onChangedPattern = {
            [weak self]
            (pattern) in
            if let s = self {
                s._updatePattern(pattern)
            }
        }
        vc.modalPresentationStyle = .Custom
        vc.transitioningDelegate = vc
        vc.parentView = self
        viewController.presentViewController(vc, animated: true, completion: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cell.frame = bounds
    }
}
