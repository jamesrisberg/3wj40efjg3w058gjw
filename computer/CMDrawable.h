//
//  CMDrawable.h
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

@import UIKit;
#import "Keyframe.h"
#import "EVInterpolation.h"
@class CMDrawableKeyframe;

@interface CMDrawableView : UIView

@end


@interface CMDrawable : NSObject <NSCoding>

- (NSArray<NSString*>*)keysForCoding;
@property (nonatomic) CGFloat boundsDiagonal;
@property (nonatomic,readonly) KeyframeStore *keyframeStore;
- (Class)keyframeClass;
@property (nonatomic,readonly) NSString *key;

- (CMDrawableView *)renderToView:(CMDrawableView *)existingOrNil atTime:(FrameTime *)time;

@end


@interface CMDrawableKeyframe : NSObject <NSCoding, EVInterpolation>

@property (nonatomic) FrameTime *frameTime;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat scale, rotation, alpha;
- (NSArray<NSString*>*)keys;

@end
