//
//  Keyframe.m
//  computer
//
//  Created by Nate Parrott on 10/20/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Keyframe.h"
#import "EVInterpolation.h"

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

@end



@implementation Keyframe

- (instancetype)init {
    self = [super init];
    self.properties = [NSMutableDictionary new];
    return self;
}

- (NSComparisonResult)compare:(Keyframe *)other {
    return [self.frameTime compare:other.frameTime];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    self.properties = [aDecoder decodeObjectForKey:@"properties"];
    self.frameTime = [aDecoder decodeObjectForKey:@"frameTime"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.properties forKey:@"properties"];
    [aCoder encodeObject:self.frameTime forKey:@"frameTime"];
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

- (void)storeKeyframe:(Keyframe *)keyframe {
    if (!self.keyframes) self.keyframes = [NSMutableArray new];
    Keyframe *existing = [self keyframeAtTime:keyframe.frameTime];
    if (existing) [self.keyframes removeObject:existing]; // TODO: make this more efficient
    [self.keyframes addObject:keyframe];
    [self.keyframes sortUsingSelector:@selector(compare:)];
}

- (Keyframe *)keyframeAtTime:(FrameTime *)time {
    // TODO: do this more efficiently:
    for (Keyframe *keyframe in self.keyframes) {
        NSComparisonResult comp = [keyframe.frameTime compare:time];
        if (comp == NSOrderedSame) {
            return keyframe;
        } else if (comp == NSOrderedDescending) {
            return nil;
        }
    }
    return nil;
}

- (Keyframe *)keyframeBeforeTime:(FrameTime *)time {
    // TODO: do this more efficiently:
    Keyframe *latest = nil;
    for (Keyframe *keyframe in self.keyframes) {
        NSComparisonResult comp = [keyframe.frameTime compare:time];
        if (comp == NSOrderedAscending) {
            latest = keyframe;
        } else {
            break;
        }
    }
    return latest;
}

- (Keyframe *)keyframeAfterTime:(FrameTime *)time {
    // TODO: do this more efficiently:
    for (Keyframe *keyframe in self.keyframes) {
        if ([time compare:keyframe.frameTime] == NSOrderedAscending) {
            return keyframe;
        }
    }
    return nil;
}

- (NSDictionary<__kindof NSString*, id>*)interpolatedPropertiesAtTime:(FrameTime *)time {
    Keyframe *exact = [self keyframeAtTime:time];
    if (exact) {
        return exact.properties;
    }
    Keyframe *before = [self keyframeBeforeTime:time];
    Keyframe *after = [self keyframeAfterTime:time];
    if (!before && after) {
        return after.properties;
    }
    if (!after && before) {
        return before.properties;
    }
    double interpolation = ([time time] - [before.frameTime time]) / ([after.frameTime time] - [before.frameTime time]);
    NSMutableDictionary *interpolated = [NSMutableDictionary new];
    NSMutableSet *allKeys = [NSMutableSet setWithArray:before.properties.allKeys];
    [allKeys addObjectsFromArray:after.properties.allKeys];
    for (NSString *key in allKeys) {
        id val = nil;
        
        id beforeVal = before.properties[key];
        id afterVal = after.properties[key];
        if (beforeVal && !afterVal) {
            val = beforeVal;
        } else if (afterVal && !beforeVal) {
            val = afterVal;
        } else if (beforeVal && afterVal) {
            val = [(id<EVInterpolation>)beforeVal interpolatedWith:afterVal progress:interpolation];
        }
        if (val) {
            interpolated[key] = val;
        }
    }
    return interpolated;
}

- (void)changePropertyAcrossTime:(NSString *)property block:(id(^)(id val))block {
    for (Keyframe *k in self.keyframes) {
        id val = k.properties[property];
        if (val) {
            k.properties[property] = block(val);
        }
    }
}

- (NSArray<__kindof Keyframe*>*)allKeyframes {
    return self.keyframes;
}

- (FrameTime *)maxTime {
    return [(Keyframe *)self.keyframes.lastObject frameTime] ? : [[FrameTime alloc] initWithFrame:0 atFPS:1];
}

- (void)removeKeyframeAtTime:(FrameTime *)time {
    Keyframe *keyframe = [self keyframeAtTime:time];
    if (keyframe) {
        [self.keyframes removeObject:keyframe]; // TODO: more efficient
    }
    if (self.keyframes.count == 0) {
        keyframe.frameTime = [[FrameTime alloc] initWithFrame:0 atFPS:1];
        [self storeKeyframe:keyframe];
    }
}

@end
