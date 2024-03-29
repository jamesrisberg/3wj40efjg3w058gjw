//
//  StickerExtractViewController.swift
//  StickerApp
//
//  Created by Nate Parrott on 9/6/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

import UIKit

class StickerExtractViewController: UIViewController, UINavigationBarDelegate {
    
    var onExtractedSticker: (UIImage -> ())?
    
    var imageToExtractFrom: UIImage? {
        didSet {
            let maxSize: CGFloat = 1000
            if let img = imageToExtractFrom {
                if img.size.width > maxSize || img.size.height > maxSize {
                    imageToExtractFrom = img.resizedWithMaxDimension(maxSize)
                }
            }
        }
    }
    private var _imageToProcess: UIImage? {
        get {
            if let img = imageToExtractFrom {
                return img.resizedWithMaxDimension(400)
            } else {
                return nil
            }
        }
    }
    var cropRect: CGRect?
    var croppedImage: UIImage? {
        get {
            if _imageToProcess != nil && cropRect != nil {
                return self._imageToProcess!.subImage(self.cropRect!)
            } else {
                return nil
            }
        }
    }
    var grabcut: Grabcut?
    
    enum State {
        case Cropping
        case Masking
    }
    
    var state: State = State.Cropping {
        didSet {
            cropDrawingImageView!.hidden = (state != State.Cropping)
            cropDrawingView!.hidden = (state != State.Cropping)
            
            maskingPulseBackground!.hidden = (state != State.Masking)
            maskingImageView!.hidden = (state != State.Masking)
            maskedImageView!.hidden = (state != State.Masking)
            maskingDrawingView!.hidden = (state != State.Masking)
            maskAddSubtractToggle!.hidden = (state != State.Masking)
            
            touchForwardingView.forwardToView = (state == State.Cropping) ? cropDrawingView : maskingDrawingView
            
            switch state {
            case .Cropping:
                cropDrawingImageView!.image = _imageToProcess
                cropDrawingView!.image = nil
            case .Masking:
                maskingImageView!.image = croppedImage
                grabcut = Grabcut(image: _imageToProcess!)
                grabcut!.maskToRect(cropRect!)
                maskedImageView!.image = grabcut!.extractImage().subImage(cropRect!)
            }
            
            view.setNeedsLayout()
        }
    }
    
    func cancel() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func done() {
        if let callback = onExtractedSticker {
            // callback(maskedImageView!.image!.imageByTrimmingTransparentPixels())
            callback(_getExtractedImage())
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var touchForwardingView : TouchForwardingView!
    
    @IBOutlet var navBar : UINavigationBar?
    var cropDrawingImageView : UIImageView?
    var cropDrawingView : DrawingView?
    
    var maskingPulseBackground : UIView?
    var maskingImageView : UIImageView?
    var maskedImageView : UIImageView?
    var maskingDrawingView : DrawingView?
    var maskAddSubtractToggle : AddSubtractToggle?
    
    var croppingNavItem = UINavigationItem()
    var maskingNavItem = UINavigationItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        touchForwardingView = TouchForwardingView(frame: view.bounds)
        view.addSubview(touchForwardingView)
        touchForwardingView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        cropDrawingImageView = UIImageView(frame: view.bounds)
        cropDrawingView = DrawingView(frame: view.bounds)
        
        maskingPulseBackground = UIView()
        maskingImageView = UIImageView(frame: view.bounds)
        maskedImageView = UIImageView(frame: view.bounds)
        maskingDrawingView = DrawingView(frame: view.bounds)
        
        maskAddSubtractToggle = AddSubtractToggle(frame: CGRectMake(0, 0, 130, 50))
        
        for child: UIView? in [cropDrawingImageView, cropDrawingView, maskingPulseBackground, maskingImageView, maskedImageView, maskingDrawingView, maskAddSubtractToggle] {
            view.addSubview(child!)
        }
        
        view.bringSubviewToFront(navBar!)
        
        self.cropDrawingView!.onTouchUp = { [weak self] in
            var rect = self!.cropDrawingView!.boundingRect!
            if rect.size.width>0 && rect.size.height>0 && CGRectIntersectsRect(rect, self!.cropDrawingImageView!.bounds) {
                /*let padding: CGFloat = (self!.view.bounds.size.width + self!.view.bounds.size.height)/2 * 0.02
                rect.origin.x -= padding
                rect.origin.y -= padding
                rect.size.width += padding*2
                rect.size.height += padding*2*/
                
                let viewSize = self!.cropDrawingImageView!.bounds.size
                let imageSize = self!.cropDrawingImageView!.image!.size
                let scaleX = imageSize.width/viewSize.width
                let scaleY = imageSize.height/viewSize.height
                let scale = CGAffineTransformMakeScale(imageSize.width/viewSize.width, imageSize.height/viewSize.height)
                // var cropRect = CGRectApplyAffineTransform(CGRectIntersection(rect, self!.cropDrawingImageView!.bounds), scale)
                var cropRect = CGRectMake(rect.origin.x * scaleX, rect.origin.y * scaleY, rect.size.width * scaleX, rect.size.height * scaleY)
                let imageBounds = CGRectMake(0, 0, imageSize.width, imageSize.height)
                cropRect = CGRectIntersection(cropRect, imageBounds)
                cropRect = CGRectIntegral(cropRect)
                
                self!.cropRect = cropRect
                self!.state = State.Masking
                self!.navBar!.pushNavigationItem(self!.maskingNavItem, animated: true)
            }
        }
        
        maskAddSubtractToggle!.adding = true
        maskAddSubtractToggle!.toggled = { [weak self] () -> () in
            self!.maskingDrawingView!.color = (self!.maskAddSubtractToggle!.adding ? UIColor.greenColor() : UIColor.redColor())
        }
        maskAddSubtractToggle!.toggled!()
        
        self.maskingDrawingView!.onTouchUp = { [weak self] in
            if let s = self {
                let size = s._imageToProcess!.size
                UIGraphicsBeginImageContextWithOptions(size, false, 1)
                UIColor.blackColor().set()
                CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height))
                s.maskingDrawingView!.image!.drawInRect(s.cropRect!)
                let mask = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                s.grabcut!.addMask(mask, foregroundColor: UIColor.greenColor(), backgroundColor: UIColor.redColor())
                s.maskedImageView!.image = s.grabcut!.extractImage().subImage(s.cropRect!)
                s.maskingDrawingView!.image = nil
            }
        }
        
        croppingNavItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        croppingNavItem.title = "Cut Out"
        croppingNavItem.prompt = "Draw a box around an object"
        maskingNavItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "done")
        maskingNavItem.prompt = "Scribble to add or remove parts of the image"
        maskingNavItem.title = "Cut Out"
        navBar!.items = [croppingNavItem]
        
        state = State.Cropping
    }
    
    var contentFrame: CGRect {
        get {
            let margin: CGFloat = 10
            let top = navBar!.frame.origin.y + navBar!.frame.size.height + margin
            return CGRectMake(margin, top, view.bounds.size.width - margin*2, view.bounds.size.height - margin - top)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        maskingPulseBackground!.frame = contentFrame
        for imageView in [cropDrawingImageView, maskingImageView, maskedImageView] {
            makeImageViewFillSuperviewRespectingAspectRatio(imageView!)
        }
        cropDrawingView!.frame = CGRectIntegral(cropDrawingImageView!.frame)
        maskingDrawingView!.frame = CGRectIntegral(maskingImageView!.frame)
        maskAddSubtractToggle!.center = CGPointMake(view.bounds.size.width/2, view.bounds.size.height - maskAddSubtractToggle!.frame.size.height/2 - 20)
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
    
    func makeImageViewFillSuperviewRespectingAspectRatio(imageView: UIImageView) {
        if let image = imageView.image {
            let scale = min(contentFrame.size.width / image.size.width, contentFrame.size.height / image.size.height)
            imageView.center = CGPointMake(contentFrame.origin.x + contentFrame.size.width/2, contentFrame.origin.y + contentFrame.size.height/2)
            imageView.bounds = CGRectMake(contentFrame.origin.x, contentFrame.origin.y, image.size.width * scale, image.size.height * scale)
        }
    }
    
    func navigationBar(navigationBar: UINavigationBar, shouldPopItem item: UINavigationItem) -> Bool {
        state = State.Cropping
        return true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        maskingPulseBackground!.backgroundColor = UIColor.blackColor()
        let bgPulse = CABasicAnimation(keyPath: "backgroundColor")
        bgPulse.fromValue = UIColor(white: 0.5, alpha: 1).CGColor
        bgPulse.toValue = UIColor(white: 0.0, alpha: 1).CGColor
        bgPulse.autoreverses = true
        bgPulse.duration = 1.4
        bgPulse.repeatCount = MAXFLOAT
        maskingPulseBackground!.layer.addAnimation(bgPulse, forKey: "pulse")
        maskingImageView!.alpha = 0.2
    }
    
    private func _getExtractedImage() -> UIImage {
        /*
        // create uncropped mask:
        UIGraphicsBeginImageContext(_imageToProcess!.size)
        maskedImageView!.image!.drawInRect(cropRect!)
        let mask = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()*/
        let maskUnflipped = maskedImageView!.image!
        UIGraphicsBeginImageContext(maskUnflipped.size)
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1, -1)
        maskUnflipped.drawInRect(CGRectMake(0, -maskUnflipped.size.height, maskUnflipped.size.width, maskUnflipped.size.height))
        let mask = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // mask the full image image:
        UIGraphicsBeginImageContext(imageToExtractFrom!.size)
        let ctx = UIGraphicsGetCurrentContext()!
        
        //CGContextTranslateCTM(ctx, 0, cropRect!.size.height);
        //CGContextScaleCTM(ctx, 1.0, -1.0);
        var crop = cropRect!
        let scale = imageToExtractFrom!.size.width / _imageToProcess!.size.width
        crop.origin.x *= scale
        crop.origin.y *= scale
        crop.size.width *= scale
        crop.size.height *= scale
        
        //CGContextScaleCTM(ctx, 1.0, -1.0);
        //CGContextTranslateCTM(ctx, 0, -crop.size.height);
        CGContextClipToMask(ctx, crop, mask.CGImage)
        
        //CGContextScaleCTM(ctx, 1.0, -1.0);
        //CGContextTranslateCTM(ctx, 0, -imageToExtractFrom!.size.height)
        
        imageToExtractFrom!.drawInRect(CGRectMake(0, 0, imageToExtractFrom!.size.width, imageToExtractFrom!.size.height))
        let extracted = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return extracted.imageByTrimmingTransparentPixels()
        // return maskedImageView!.image!.imageByTrimmingTransparentPixels()
    }
}
