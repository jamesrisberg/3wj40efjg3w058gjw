//
//  Keyframe.h
//  computer
//
//  Created by Nate Parrott on 10/20/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CMDrawableKeyframe;
#import "EVInterpolation.h"

@interface FrameTime : NSObject <NSCoding, EVInterpolation>

// frameTime will be converted to lowest-common-denominator
- (instancetype)initWithFrame:(NSInteger)frame atFPS:(NSInteger)fps;

@property (nonatomic,readonly) NSInteger frame, fps;
- (NSTimeInterval)time;

- (FrameTime *)maxWith:(FrameTime *)other;

- (NSComparisonResult)compare:(FrameTime *)other;

+ (FrameTime *)leastCommonMultipleForTimes:(NSArray<__kindof FrameTime*>*)times maxTime:(NSTimeInterval)max;

- (FrameTime *)byAdding:(FrameTime *)time;
- (FrameTime *)bySubtracting:(FrameTime *)time;

@end

@interface KeyframeStore : NSObject <NSCoding>

- (void)storeKeyframe:(CMDrawableKeyframe *)keyframe;
- (__kindof CMDrawableKeyframe *)keyframeAtTime:(FrameTime *)time;
- (__kindof CMDrawableKeyframe *)keyframeBeforeTime:(FrameTime *)time;
- (__kindof CMDrawableKeyframe *)keyframeAfterTime:(FrameTime *)time;
- (__kindof CMDrawableKeyframe *)interpolatedKeyframeAtTime:(FrameTime *)time;
- (__kindof CMDrawableKeyframe *)createKeyframeAtTimeIfNeeded:(FrameTime *)time;

- (void)changePropertyAcrossTime:(NSString *)property block:(id(^)(id val))block;
- (NSArray<__kindof CMDrawableKeyframe*>*)allKeyframes;

- (FrameTime *)maxTime;

- (void)removeKeyframeAtTime:(FrameTime *)time;

@property (nonatomic) Class keyframeClass;

@property (nonatomic) FrameTime *motionDuration;

@end

