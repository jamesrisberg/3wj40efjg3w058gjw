//
//  TransitionPickerView.swift
//  computer
//
//  Created by Nate Parrott on 12/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

import UIKit

class TransitionPickerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        enterExitContainer = UIView()
        addSubview(enterExitContainer)
        enterButton = UIButton()
        enterButton.setTitle(NSLocalizedString("Entrance", comment: ""), forState: .Normal)
        enterButton.addTarget(self, action: "addEntranceAnimation:", forControlEvents: .TouchUpInside)
        exitButton = UIButton()
        exitButton.setTitle(NSLocalizedString("Exit", comment: ""), forState: .Normal)
        exitButton.addTarget(self, action: "addExitAnimation:", forControlEvents: .TouchUpInside)
        for btn in [enterButton, exitButton] {
            enterExitContainer.addSubview(btn)
            btn.titleLabel!.font = UIFont.boldSystemFontOfSize(12)
        }
        
        transitionPicker = HorizontalItemPicker(frame: bounds)
        addSubview(transitionPicker)
        transitionPicker.onSelectionChange = {
            [weak self]
            (index: Int?) -> () in
            if let i = index {
                if i == 0 {
                    self!.transition = nil
                } else {
                    self!.transition = self!.showingTransitionClasses[i-1]
                }
                if let cb = self!.onPickedTransition {
                    cb(self!.transition)
                }
            }
        }
        
        _transitionChanged()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var enterExitContainer: UIView!
    var enterButton: UIButton!
    var exitButton: UIButton!
    var transitionPicker: HorizontalItemPicker!
    var showingTransitionClasses = [Transition.Type]() {
        didSet {
            transitionPicker.strings = [NSLocalizedString("None", comment: "")] + showingTransitionClasses.map({ $0.displayName })
        }
    }
    
    var _enabled = true {
        didSet {
            for btn in [enterButton, exitButton] {
                btn.alpha = _enabled ? 1 : 0.5
            }
            userInteractionEnabled = _enabled
        }
    }
    
    dynamic var drawable: CMDrawable? {
        didSet {
            _enabled = (drawable != nil)
            _transitionChanged()
        }
    }
    
    var transition: Transition.Type? {
        didSet {
            _transitionChanged()
        }
    }
    var onPickedTransition: (Transition.Type? -> ())?
    
    private func _transitionChanged() {
        enterExitContainer.alpha = 0
        transitionPicker.alpha = 0
        
        if let t = transition {
            let isEntrance: Bool = t.isEntranceAnimation
            showingTransitionClasses = availableTransitions(isEntrance)
            if let i = showingTransitionClasses.indexOf({ $0 === t }) {
                transitionPicker.selectedIndex = i + 1
            }
            transitionPicker.alpha = 1
        } else {
            enterExitContainer.alpha = 1
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        enterExitContainer.frame = bounds
        enterButton.frame = CGRectMake(0, 0, bounds.size.width/2, bounds.size.height)
        exitButton.frame = CGRectMake(bounds.size.width/2, 0, bounds.size.width/2, bounds.size.height)
        transitionPicker.frame = bounds
    }
    
    func availableTransitions(entrance: Bool) -> [Transition.Type] {
        if let selection = self.drawable {
            return Transition.allTransitions.filter({ $0.isEntranceAnimation == entrance && $0.canApplyToDrawable(selection) })
        } else {
            return []
        }
    }
    
    func addEntranceAnimation(sender: UIButton) {
        transition = availableTransitions(true).first!
        if let cb = onPickedTransition {
            cb(transition)
        }
    }
    
    func addExitAnimation(sender: UIButton) {
        transition = availableTransitions(false).first!
        if let cb = onPickedTransition {
            cb(transition)
        }
    }
    
    func setTransitionFromKeyframe(keyframe: CMDrawableKeyframe?) {
        transition = keyframe?.transition?.dynamicType
    }
}
