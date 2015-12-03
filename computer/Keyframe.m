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

@end

@interface KeyframeStore ()

@property (nonatomic) NSMutableArray *keyframes;

@end

@implementation KeyframeStore

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.keyframes = [aDecoder decodeObjectForKey:@"keyframes"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.keyframes forKey:@"keyframes"];
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
    CMDrawableKeyframe *before = [self keyframeBeforeTime:time];
    CMDrawableKeyframe *after = [self keyframeAfterTime:time];
    if (!before && after) {
        return after;
    }
    if (!after && before) {
        return before;
    }
    double interpolation = ([time time] - [before.frameTime time]) / ([after.frameTime time] - [before.frameTime time]);
    return [before interpolatedWith:after progress:interpolation];
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
    /*for (CMDrawableKeyframe *k in self.keyframes) {
        id val = k.properties[property];
        if (val) {
            k.properties[property] = block(val);
        }
    }*/
    // TODO
}

- (NSArray<__kindof CMDrawableKeyframe*>*)allKeyframes {
    return self.keyframes;
}

- (FrameTime *)maxTime {
    return [(CMDrawableKeyframe *)self.keyframes.lastObject frameTime] ? : [[FrameTime alloc] initWithFrame:0 atFPS:1];
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
