//
//  AVAssetTrack+Orientation.m
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "AVAssetTrack+Orientation.h"

@implementation AVAssetTrack (Orientation)

- (CGImagePropertyOrientation)orientation {
    CGAffineTransform txf = [self preferredTransform];
    CGFloat videoAngleRadians = atan2(txf.b, txf.a);
    CGFloat videoAngleDegrees = videoAngleRadians / M_PI * 180;
    if (videoAngleDegrees == 0) {
        return kCGImagePropertyOrientationUp;
    } else if (videoAngleDegrees == 90) {
        return kCGImagePropertyOrientationRight;
    } else if (videoAngleDegrees == 180) {
        return kCGImagePropertyOrientationDown;
    } else if (videoAngleDegrees == 270) {
        return kCGImagePropertyOrientationLeft;
    }
    return kCGImagePropertyOrientationUp; // shouldn't happen (?)
}

@end
