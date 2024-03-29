//
//  EVInterpolation.m
//  Elastic
//
//  Created by Nate Parrott on 6/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EVInterpolation.h"

CGRect EVInterpolateRect(CGRect r1, CGRect r2, CGFloat progress) {
    return (CGRect){EVInterpolatePoint(r1.origin, r2.origin, progress), EVInterpolateSize(r1.size, r2.size, progress)};
}

CGPoint EVInterpolatePoint(CGPoint sourceValue, CGPoint targetValue, CGFloat progress) {
    return CGPointMake(EVInterpolate(sourceValue.x, targetValue.x, progress), EVInterpolate(sourceValue.y, targetValue.y, progress));
}

CGSize EVInterpolateSize(CGSize s1, CGSize s2, CGFloat progress) {
    return CGSizeMake(EVInterpolate(s1.width, s2.width, progress), EVInterpolate(s1.height, s2.height, progress));
}

CGFloat EVInterpolate(CGFloat a1, CGFloat a2, CGFloat progress) {
    return a1 * (1 - progress) + a2 * progress;
}

CGFloat EVInterpolateAngles(CGFloat a1, CGFloat a2, CGFloat progress) {
    CGFloat x = cos(a1) * (1 - progress) + cos(a2) * progress;
    CGFloat y = sin(a1) * (1 - progress) + sin(a2) * progress;
    if (x == 0 && y == 0) {
        return a1;
    } else {
        return atan2(y, x);
    }
}

CGFloat EVCatmullRom(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat p3, CGFloat t) {
    // from http://tehc0dez.blogspot.com/2010/04/nice-curves-catmullrom-spline-in-c.html
    
    float t2 = t * t;
    float t3 = t2 * t;
    
    return 0.5f * ((2.0f * p1) +
                   (-p0 + p2) * t +
                   (2.0f * p0 - 5.0f * p1 + 4 * p2 - p3) * t2 +
                   (-p0 + 3.0f * p1 - 3.0f * p2 + p3) * t3);
}


@implementation NSNumber (EVInterpolation)

- (instancetype)interpolatedWith:(id)other progress:(CGFloat)progress {
    return @([self doubleValue] * (1 - progress) + [other doubleValue] * progress);
}

- (instancetype)interpolatedWith:(id)other progress:(CGFloat)progress previousVal:(id)prev nextVal:(id)next {
    return @(EVCatmullRom([prev doubleValue], [self doubleValue], [other doubleValue], [next doubleValue], progress));
}

@end

@implementation NSValue (EVInterpolation)

- (instancetype)interpolatedWith:(id)target progress:(CGFloat)progress {
    // via https://github.com/rpetrich/CAKeyframeAnimation-Generation/blob/master/NSValue%2BInterpolation.m
    const char *sourceType = [self objCType];
    const char *targetType = [target objCType];
    if (strcmp(sourceType, targetType) != 0) {
        // Types don't match!
        return nil;
    }
    CGFloat remainingProgress = 1.0 - progress;
    if (strcmp(targetType, @encode(CGPoint)) == 0) {
        CGPoint sourceValue = [self CGPointValue];
        CGPoint targetValue = [target CGPointValue];
        CGPoint finalValue;
        finalValue.x = sourceValue.x * remainingProgress + targetValue.x * progress;
        finalValue.y = sourceValue.y * remainingProgress + targetValue.y * progress;
        return [NSValue valueWithCGPoint:finalValue];
    }
    if (strcmp(targetType, @encode(CGSize)) == 0) {
        CGSize sourceValue = [self CGSizeValue];
        CGSize targetValue = [target CGSizeValue];
        CGSize finalValue;
        finalValue.width = sourceValue.width * remainingProgress + targetValue.width * progress;
        finalValue.height = sourceValue.height * remainingProgress + targetValue.height * progress;
        return [NSValue valueWithCGSize:finalValue];
    }
    if (strcmp(targetType, @encode(CGRect)) == 0) {
        CGRect sourceValue = [self CGRectValue];
        CGRect targetValue = [target CGRectValue];
        CGRect finalValue;
        finalValue.origin.x = sourceValue.origin.x * remainingProgress + targetValue.origin.x * progress;
        finalValue.origin.y = sourceValue.origin.y * remainingProgress + targetValue.origin.y * progress;
        finalValue.size.width = sourceValue.size.width * remainingProgress + targetValue.size.width * progress;
        finalValue.size.height = sourceValue.size.height * remainingProgress + targetValue.size.height * progress;
        return [NSValue valueWithCGRect:finalValue];
    }
    return nil;
}

- (instancetype)interpolatedWith:(id)other progress:(CGFloat)progress previousVal:(id)prev nextVal:(id)next  {
    const char *sourceType = [self objCType];
    const char *targetType = [other objCType];
    if (strcmp(sourceType, targetType) != 0) {
        // Types don't match!
        return nil;
    }
    if (strcmp(sourceType, @encode(CGPoint)) == 0) {
        CGPoint p0 = [prev CGPointValue];
        CGPoint p1 = [self CGPointValue];
        CGPoint p2 = [other CGPointValue];
        CGPoint p3 = [next CGPointValue];
        CGFloat x = EVCatmullRom(p0.x, p1.x, p2.x, p3.x, progress);
        CGFloat y = EVCatmullRom(p0.y, p1.y, p2.y, p3.y, progress);
        return [NSValue valueWithCGPoint:CGPointMake(x, y)];
    } else {
        return [self interpolatedWith:other progress:progress];
    }
}

@end
