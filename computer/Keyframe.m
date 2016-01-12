//
//  Keyframe.m
//  computer
//
//  Created by Nate Parrott on 10/20/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Keyframe.h"
#import "EVInterpolation.h"
#import "CMShapeDrawable.h"
#import "computer-Swift.h"
#import "VideoConstants.h"

NSInteger _FrameTimeGCD(NSInteger a, NSInteger b) {
    while (b != 0) {
        NSInteger t = b;
        b = a % b;
        a = t;
    }
    return a;
}

@interface FrameTime ()

@property (nonatomic) NSInteger frame, fps;

@end

@implementation FrameTime

- (instancetype)initWithFrame:(NSInteger)frame atFPS:(NSInteger)fps {
    self = [super init];
    NSInteger gcd = _FrameTimeGCD(frame, fps);
    _frame = frame / gcd;
    _fps = fps / gcd;
    return self;
}

- (NSUInteger)hash {
    return [@(_frame) hash] ^ [@(_fps) hash];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[FrameTime class]] && _frame == [(FrameTime *)object frame] && _frame == [(FrameTime *)object fps];
}

- (NSTimeInterval)time {
    return _frame / (NSTimeInterval)_fps;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<FrameTime: %@s>", @([self time])];
}

- (NSComparisonResult)compare:(FrameTime *)other {
    if (self.time < other.time) {
        return NSOrderedAscending;
    } else if (self.time > other.time) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _frame = [aDecoder decodeIntegerForKey:@"frame"];
    _fps = [aDecoder decodeIntegerForKey:@"fps"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_frame forKey:@"frame"];
    [aCoder encodeInteger:_fps forKey:@"fps"];
}

- (FrameTime *)maxWith:(FrameTime *)other {
    if (self.time > other.time) {
        return self;
    } else {
        return other;
    }
}

+ (FrameTime *)leastCommonMultipleForTimes:(NSArray<__kindof FrameTime*>*)times maxTime:(NSTimeInterval)max {
    return nil; // TODO
}

- (instancetype)interpolatedWith:(id)other progress:(CGFloat)progress {
    NSInteger m = 10000;
    return [[FrameTime alloc] initWithFrame:(self.time + [(FrameTime *)other time]) * m / 2 atFPS:m];
}

- (FrameTime *)byAdding:(FrameTime *)other {
    return [[FrameTime alloc] initWithFrame:self.frame * other.fps + other.frame * self.fps atFPS:self.fps * other.fps];
}

- (FrameTime *)bySubtracting:(FrameTime *)other {
    return [[FrameTime alloc] initWithFrame:self.frame * other.fps - other.frame * self.fps atFPS:self.fps * other.fps];
}

@end

@interface KeyframeStore ()

@property (nonatomic) NSMutableArray *keyframes;

@end

@implementation KeyframeStore

- (instancetype)init {
    self = [super init];
    self.motionDuration = [[FrameTime alloc] initWithFrame:1 atFPS:VC_TIMELINE_CELLS_PER_SECOND];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.keyframes = [aDecoder decodeObjectForKey:@"keyframes"];
    self.motionDuration = [aDecoder decodeObjectForKey:@"motionDuration"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.keyframes forKey:@"keyframes"];
    [aCoder encodeObject:self.motionDuration forKey:@"motionDuration"];
}

- (void)storeKeyframe:(CMDrawableKeyframe *)keyframe {
    if (!self.keyframes) self.keyframes = [NSMutableArray new];
    CMDrawableKeyframe *existing = [self keyframeAtTime:keyframe.frameTime];
    if (existing) [self.keyframes removeObject:existing]; // TODO: make this more efficient
    [self.keyframes addObject:keyframe];
    [self.keyframes sortUsingSelector:@selector(compare:)];
}

- (CMDrawableKeyframe *)keyframeAtTime:(FrameTime *)time {
    // TODO: do this more efficiently:
    for (CMDrawableKeyframe *keyframe in self.keyframes) {
        NSComparisonResult comp = [keyframe.frameTime compare:time];
        if (comp == NSOrderedSame) {
            return keyframe;
        } else if (comp == NSOrderedDescending) {
            return nil;
        }
    }
    return nil;
}

- (CMDrawableKeyframe *)keyframeBeforeTime:(FrameTime *)time {
    // TODO: do this more efficiently:
    CMDrawableKeyframe *latest = nil;
    for (CMDrawableKeyframe *keyframe in self.keyframes) {
        NSComparisonResult comp = [keyframe.frameTime compare:time];
        if (comp == NSOrderedAscending) {
            latest = keyframe;
        } else {
            break;
        }
    }
    return latest;
}

- (CMDrawableKeyframe *)keyframeAfterTime:(FrameTime *)time {
    // TODO: do this more efficiently:
    for (CMDrawableKeyframe *keyframe in self.keyframes) {
        if ([time compare:keyframe.frameTime] == NSOrderedAscending) {
            return keyframe;
        }
    }
    return nil;
}

- (CMDrawableKeyframe *)_interpolatedKeyframeAtTime:(FrameTime *)time {
    CMDrawableKeyframe *exact = [self keyframeAtTime:time];
    if (exact) {
        return exact;
    }
    
    /*
     the animation starts self.motionDuration seconds before the keyframe
     */
    
    CMDrawableKeyframe *prev = [[self keyframeBeforeTime:time] copy];
    if (prev.transition && ![[prev.transition class] isEntranceAnimation] && time.time >= prev.transition.endTime.time) {
        // we're directly after an exit transition, so pretend we have a `from` opacity of 0:
        prev.alpha = 0;
    }
    
    CMDrawableKeyframe *next = [[self keyframeAfterTime:time] copy];
    if (next.transition && [[next.transition class] isEntranceAnimation] && time.time <= next.transition.endTime.time) {
        // `time` comes directly before an entrance transition, so pretend we have a `to` opacity of 0:
        next.alpha = 0;
    }
    
    FrameTime *animationStartTime = [next.frameTime bySubtracting:self.motionDuration];
    if (time.time < animationStartTime.time) {
        // the animation hasn't actually started yet;
        next = [prev copy];
        next.frameTime = animationStartTime;
    } else {
        prev.frameTime = animationStartTime;
    }
    
    CMDrawableKeyframe *beforePrev = prev ? [self keyframeBeforeTime:prev.frameTime] : nil;
    CMDrawableKeyframe *afterNext = next ? [self keyframeAfterTime:next.frameTime] : nil;
    
    CMDrawableKeyframe *interpolation = nil;
    
    if (!prev && next) {
        interpolation = [next copy];
    } else if (!next && prev) {
        interpolation = [prev copy];
    } else {
        double progress = ([time time] - [prev.frameTime time]) / ([next.frameTime time] - [prev.frameTime time]);
        interpolation = [prev interpolatedWith:next progress:progress previousVal:beforePrev nextVal:afterNext];
    }
    
    // if this intersects a transition, carry it (multiple transitions at once aren't supported):
    if (prev.transition && [prev.transition containsTime:time]) {
        interpolation.transition = prev.transition;
    } else if (next.transition && [next.transition containsTime:time]) {
        interpolation.transition = next.transition;
    } else {
        interpolation.transition = nil;
    }
    return interpolation;
}

- (CMDrawableKeyframe *)interpolatedKeyframeAtTime:(FrameTime *)time {
    CMDrawableKeyframe *k = [[self _interpolatedKeyframeAtTime:time] copy];
    k.frameTime = time;
    return k;
}

- (CMDrawableKeyframe *)createKeyframeAtTimeIfNeeded:(FrameTime *)time {
    CMDrawableKeyframe *k = [self keyframeAtTime:time];
    if (!k) {
        k = [[self interpolatedKeyframeAtTime:time] copy] ? : [self.keyframeClass new];
        k.frameTime = time;
        [self storeKeyframe:k];
    }
    return k;
}

- (void)changePropertyAcrossTime:(NSString *)property block:(id(^)(id val))block {
    for (CMDrawableKeyframe *k in self.keyframes) {
        id val = [k valueForKey:property];
        if (val) {
            [k setValue:block(val) forKey:property];
        }
    }
}

- (NSArray<__kindof CMDrawableKeyframe*>*)allKeyframes {
    return self.keyframes;
}

- (FrameTime *)maxTime {
    CMDrawableKeyframe *lastKeyframe = self.keyframes.lastObject;
    if (lastKeyframe) {
        if (lastKeyframe.transition) {
            return lastKeyframe.transition.endTime;
        } else {
            return lastKeyframe.frameTime;
        }
    } else {
        return [[FrameTime alloc] initWithFrame:0 atFPS:1];
    }
}

- (void)removeKeyframeAtTime:(FrameTime *)time {
    CMDrawableKeyframe *keyframe = [self keyframeAtTime:time];
    if (keyframe) {
        [self.keyframes removeObject:keyframe]; // TODO: more efficient
    }
    if (self.keyframes.count == 0) {
        keyframe.frameTime = [[FrameTime alloc] initWithFrame:0 atFPS:1];
        [self storeKeyframe:keyframe];
    }
}

@end
