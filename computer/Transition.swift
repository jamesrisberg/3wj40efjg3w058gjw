//
//  Transition.swift
//  computer
//
//  Created by Nate Parrott on 12/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

import UIKit

class Transition: NSObject, NSCoding {
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        uuid = aDecoder.decodeObjectForKey("uuid") as! String
        startTime = aDecoder.decodeObjectForKey("startTime") as! FrameTime?
        // startOffset = aDecoder.decodeObjectForKey("startOffset") as! FrameTime
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(uuid, forKey: "uuid")
        aCoder.encodeObject(startTime, forKey: "startTime")
        // aCoder.encodeObject(startOffset, forKey: "startOffset")
    }
    
    class var displayName: String! {
        get {
            return nil
        }
    }
    
    dynamic class var isEntranceAnimation: Bool {
        get {
            return false
        }
    }
    
    func apply(drawable: CMDrawable, view: CMDrawableView, context: CMRenderContext, progress: CGFloat) {
        
    }
    
    func containsTime(time: FrameTime) -> Bool {
        if let start = startTime, end = endTime {
            return time.time() >= start.time() && time.time() <= end.time()
        } else {
            return false
        }
    }
    
    // var startOffset: FrameTime = FrameTime(frame: 0, atFPS: 1)
    var startTime: FrameTime?
    
    var duration: FrameTime! {
        get {
            return FrameTime(frame: 1, atFPS: 4)
        }
    }
    
    var endTime: FrameTime? {
        get {
            return startTime?.byAdding(duration)
        }
    }
    
    var uuid = NSUUID().UUIDString
    
    static let allTransitions: [Transition.Type] = [
        FadeOutTransition.self,
        FadeInTransition.self,
        ShrinkAwayTransition.self
    ]
}

class FadeOutTransition: Transition {
    override class var displayName: String! {
        get {
            return NSLocalizedString("Fade out", comment: "")
        }
    }
    override class var isEntranceAnimation: Bool {
        get {
            return false
        }
    }
    override func apply(drawable: CMDrawable, view: CMDrawableView, context: CMRenderContext, progress: CGFloat) {
        view.alpha *= (1.0 - progress)
    }
}

class FadeInTransition: Transition {
    override class var displayName: String! {
        get {
            return NSLocalizedString("Fade in", comment: "")
        }
    }
    override class var isEntranceAnimation: Bool {
        get {
            return true
        }
    }
    override func apply(drawable: CMDrawable, view: CMDrawableView, context: CMRenderContext, progress: CGFloat) {
        view.alpha *= progress
    }
}

class ShrinkAwayTransition: Transition {
    override class var displayName: String! {
        get {
            return NSLocalizedString("Shrink away", comment: "")
        }
    }
    override class var isEntranceAnimation: Bool {
        get {
            return false
        }
    }
    override func apply(drawable: CMDrawable, view: CMDrawableView, context: CMRenderContext, progress: CGFloat) {
        view.transform = CGAffineTransformScale(view.transform, 1.0 - progress, 1.0 - progress)
    }
}
