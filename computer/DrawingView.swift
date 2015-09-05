//
//  DrawingView.swift
//  Backgrounder
//
//  Created by Nate Parrott on 6/15/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

import UIKit

class DrawingView: UIImageView {
    override init(frame: CGRect) {
        color = UIColor.blackColor()
        super.init(frame: frame)
        userInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        color = UIColor.blackColor()
        super.init(coder: aDecoder)
        userInteractionEnabled = true
    }
    var color: UIColor
    var lineWidth: CGFloat = 10.0
    
    var lastTouchPos: CGPoint?
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        lastTouchPos = touches.first!.locationInView(self)
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touchPos = touches.first!.locationInView(self)
        addLineFrom(lastTouchPos!, to: touchPos)
        lastTouchPos = touchPos
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touchPos = touches.first!.locationInView(self)
        addLineFrom(lastTouchPos!, to: touchPos)
        
        if let cb = onTouchUp {
            cb()
        }
    }
    
    func addLineFrom(from: CGPoint, to: CGPoint) {
        addPointToBoundingRect(from)
        addPointToBoundingRect(to)
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        if let image = self.image {
            image.drawInRect(self.bounds)
        }
        color.set()
        let path = UIBezierPath()
        path.moveToPoint(from)
        path.addLineToPoint(to)
        path.lineCapStyle = .Round
        path.lineWidth = lineWidth
        path.stroke()
        self.image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
    }
    
    var onTouchUp: (()->())?
    
    var boundingRect: CGRect?
    func addPointToBoundingRect(point: CGPoint) {
        if let r = boundingRect {
            var minX = r.origin.x
            var minY = r.origin.y
            var maxX = minX + r.size.width
            var maxY = minY + r.size.height
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
            boundingRect = CGRectMake(minX, minY, maxX-minX, maxY-minY)
        } else {
            boundingRect = CGRectMake(point.x, point.y, 0, 0)
        }
    }
}
