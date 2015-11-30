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

@end

@interface KeyframeStore : NSObject <NSCoding>

- (void)storeKeyframe:(CMDrawableKeyframe *)keyframe;
- (CMDrawableKeyframe *)keyframeAtTime:(FrameTime *)time;
- (CMDrawableKeyframe *)keyframeBeforeTime:(FrameTime *)time;
- (CMDrawableKeyframe *)keyframeAfterTime:(FrameTime *)time;
- (CMDrawableKeyframe *)interpolatedKeyframeAtTime:(FrameTime *)time;
- (CMDrawableKeyframe *)createKeyframeAtTimeIfNeeded:(FrameTime *)time;

- (void)changePropertyAcrossTime:(NSString *)property block:(id(^)(id val))block;
- (NSArray<__kindof CMDrawableKeyframe*>*)allKeyframes;

- (FrameTime *)maxTime;

- (void)removeKeyframeAtTime:(FrameTime *)time;

@property (nonatomic) Class keyframeClass;

@end

@protocol TimeAware <NSObject>

@property (nonatomic) BOOL useTimeForStaticAnimations;
@property (nonatomic) FrameTime *time;
@property (nonatomic) BOOL suppressTimingVisualizations; // e.g. dimming

@end
