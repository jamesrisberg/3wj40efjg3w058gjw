//
//  CGPointExtras.c
//  Sketch
//
//  Created by Nate Parrott on 6/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <Foundation/Foundation.h>
#import "CGPointExtras.h"

const CGPoint CGPointNull = {-999999999, -999999999};
BOOL CGPointIsNull(CGPoint p) {
    return CGPointEqualToPoint(p, CGPointNull);
}
CGFloat CGPointDistance(CGPoint p1, CGPoint p2) {
    return sqrtf(powf(p1.x-p2.x, 2) + powf(p1.y-p2.y, 2));
}

const CGFloat CGPointStandardSnappingThreshold = 15;
CGFloat CGSnap(CGFloat x, CGFloat range) {
    return CGSnapWithThreshold(x, range, CGPointStandardSnappingThreshold);
}
CGFloat CGSnapWithThreshold(CGFloat x, CGFloat range, CGFloat threshold) {
    if (x <= threshold) {
        return 0;
    } else if (x >= range-threshold) {
        return range;
    } else if (fabs(x-range/2) <= threshold) {
        return range/2;
    } else {
        return x;
    }
}
CGFloat CGPointAngleBetween(CGPoint p1, CGPoint p2) {
    return atan2(p2.y-p1.y, p2.x-p1.x);
}
CGPoint CGPointShift(CGPoint p, CGFloat direction, CGFloat distance) {
    return CGPointMake(p.x + cos(direction)*distance, p.y + sin(direction)*distance);
}
CGPoint CGPointMidpoint(CGPoint p1, CGPoint p2) {
    return CGPointShift(p1, CGPointAngleBetween(p1, p2), CGPointDistance(p1, p2)/2);
}

CGFloat CGTransformByAddingPadding(CGFloat p, CGFloat padding, CGFloat range) {
    return padding + (p/range) * (range-padding*2);
}
CGFloat CGTransformByRemovingPadding(CGFloat p, CGFloat padding, CGFloat range) {
    return MAX(0, MIN(range, (p-padding)/(range-padding*2)*range));
}
CGPoint CGPointLinearlyInterpolate(CGPoint p1, CGPoint p2, CGFloat progress) {
    return CGPointMake(p1.x * (1 - progress) + p2.x * progress, p1.y * (1 - progress) + p2.y * progress);
}

CGPoint CGPointAdd(CGPoint p1, CGPoint p2) {
    return CGPointMake(p1.x+p2.x, p1.y+p2.y);
}
CGPoint CGPointScale(CGPoint p, CGFloat scale) {
    return CGPointMake(p.x*scale, p.y*scale);
}

CGPoint NPEvaluateSmoothCurve(CGPoint prevPoint, CGPoint fromPoint, CGPoint toPoint, CGPoint nextPoint, CGFloat progress, BOOL ignorePreviousPointDistance) {
    
    CGFloat distanceBetween = 0;
    if (ignorePreviousPointDistance) distanceBetween = CGPointDistance(fromPoint, toPoint);
    
    CGPoint controlPoint1 = toPoint;
    if (!CGPointEqualToPoint(fromPoint, prevPoint)) {
        CGFloat controlPointDist = ignorePreviousPointDistance ? distanceBetween : CGPointDistance(fromPoint, prevPoint);
        CGFloat controlPointAngle = M_PI + CGPointDistance(fromPoint, prevPoint);
        controlPoint1 = CGPointShift(fromPoint, controlPointAngle, controlPointDist);
    }
    
    CGPoint controlPoint2 = fromPoint;
    if (!CGPointEqualToPoint(toPoint, nextPoint)) {
        CGFloat controlPointDist = ignorePreviousPointDistance ? distanceBetween : CGPointDistance(toPoint, nextPoint);
        CGFloat controlPointAngle = M_PI + CGPointAngleBetween(toPoint, nextPoint);
        controlPoint2 = CGPointShift(fromPoint, controlPointAngle, controlPointDist);
    }
    
    CGPoint incomingTangent = CGPointLinearlyInterpolate(fromPoint, controlPoint1, progress);
    CGPoint outgoingTangent = CGPointLinearlyInterpolate(toPoint, controlPoint2, progress);
    return CGPointLinearlyInterpolate(incomingTangent, outgoingTangent, progress);
}

