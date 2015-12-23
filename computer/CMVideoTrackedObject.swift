//
//  CMVideoTrackedObject.swift
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

import UIKit

class CMVideoTrackedObject: NSObject, NSCoding {
    var name: String = "Object"
    var uuid: String = NSUUID().UUIDString
    
    struct Sample {
        let time: NSTimeInterval
        let bounds: CGRect
        let rotation: CGFloat
        let center: CGPoint
        func interpolateWith(other: Sample, progress: CGFloat) -> Sample {
            let p1 = 1.0 - progress
            return Sample(time: time*Double(p1) + other.time*Double(progress), bounds: EVInterpolateRect(bounds, other.bounds, progress), rotation: EVInterpolateAngles(rotation, other.rotation, progress), center: EVInterpolatePoint(center, other.center, progress))
        }
        func toDict() -> [String: AnyObject] {
            return ["time": time, "bounds": NSValue(CGRect: bounds), "rotation": rotation, "center": NSValue(CGPoint: center)]
        }
        static func fromDict(dict: [String: AnyObject]) -> Sample {
            return Sample(time: (dict["time"] as! NSNumber).doubleValue, bounds: (dict["bounds"] as! NSValue).CGRectValue(), rotation: CGFloat((dict["rotation"] as! NSNumber).floatValue), center: (dict["center"] as! NSValue).CGPointValue())
        }
    }
    private var _samples = [Sample]()
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        for sample in aDecoder.decodeObjectForKey("samples") as! [[String: AnyObject]] {
            _samples.append(Sample.fromDict(sample))
        }
        uuid = aDecoder.decodeObjectForKey("uuid") as! String
        name = aDecoder.decodeObjectForKey("name") as! String
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        let sampleDicts = _samples.map({ $0.toDict() })
        aCoder.encodeObject(sampleDicts, forKey: "samples")
        aCoder.encodeObject(name, forKey: "name")
        aCoder.encodeObject(uuid, forKey: "uuid")
    }
    
    func appendSample(feature: CIFaceFeature, imageSize: CGSize, transform: CGAffineTransform, time: NSTimeInterval) {
        var normalization = CGSizeApplyAffineTransform(imageSize, transform)
        normalization = CGSizeMake(fabs(normalization.width), fabs(normalization.height))
        
        var bounds = feature.bounds
        bounds.origin.y = imageSize.height - bounds.origin.y - bounds.size.height
        bounds = CGRectApplyAffineTransform(bounds, transform)
        let boundsNormalized = CGRectMake(bounds.origin.x / imageSize.width - 0.5, bounds.origin.y / imageSize.height - 0.5, bounds.size.width / normalization.width, bounds.size.height / normalization.height)
        
        var center = CGPointMake((feature.mouthPosition.x + feature.leftEyePosition.x + feature.rightEyePosition.x) / 3.0, (feature.mouthPosition.y + feature.leftEyePosition.y + feature.rightEyePosition.y) / 3.0)
        center.y = imageSize.height - center.y
        center = CGPointApplyAffineTransform(center, transform)
        center = CGPointMake(center.x / normalization.width - 0.5, center.y / normalization.height - 0.5)
        
        // center = CGPointMake(CGRectGetMidX(boundsNormalized), CGRectGetMidY(boundsNormalized))
        
        // boundsNormalized = CGRectApplyAffineTransform(boundsNormalized, transform)
        let sample = Sample(time: time, bounds: boundsNormalized, rotation: feature.hasFaceAngle ? CGFloat(feature.faceAngle) : 0.0, center: center)
        _samples.append(sample)
    }
    
    var frameCount: Int {
        get {
            return _samples.count
        }
    }
    
    var minFrameTime: NSTimeInterval {
        get {
            return _samples[0].time
        }
    }
    
    var maxFrameTime: NSTimeInterval {
        get {
            return _samples.last!.time
        }
    }
    
    func appendFramesFromObject(object: CMVideoTrackedObject) {
        _samples.appendContentsOf(object._samples)
    }
    
    func overlapsWithOtherObjectTemporally(object: CMVideoTrackedObject) -> Bool {
        if minFrameTime <= object.minFrameTime {
            return maxFrameTime >= object.minFrameTime
        } else {
            return object.overlapsWithOtherObjectTemporally(self)
        }
    }
    
    private func _interpolatedSampleAtTime(time: NSTimeInterval) -> Sample {
        var low = 0
        var high = _samples.count
        var prevMid = -1
        while (low + high) / 2 != prevMid {
            let mid = (low + high) / 2
            if _samples[mid].time < time {
                low = mid
            } else if _samples[mid].time > time {
                high = mid
            } else {
                // they're equal:
                return _samples[mid]
            }
            prevMid = mid
        }
        
        let sample1 = _samples[prevMid]
        if time < sample1.time {
            return sample1
        } else {
            if prevMid + 1 < _samples.count {
                let sample2 = _samples[prevMid+1]
                let progress = (time - sample1.time) / (sample2.time - sample1.time)
                return sample1.interpolateWith(sample2, progress: CGFloat(progress))
            } else {
                return sample1
            }
        }
    }
    
    private func _rectSize(rect: CGRect) -> CGFloat {
        return sqrt(pow(rect.size.width, 2.0) + pow(rect.size.height, 2.0))
    }
    
    func layoutBaseAtTime(time: NSTimeInterval) -> CMLayoutBase {
        let sample = _interpolatedSampleAtTime(time)
        let layout = CMLayoutBase()
        layout.scale = _rectSize(sample.bounds) / _rectSize(_samples[0].bounds)
        // layout.rotation = sample.rotation
        layout.center = sample.center
        layout.visible = true
        return layout
    }
}
