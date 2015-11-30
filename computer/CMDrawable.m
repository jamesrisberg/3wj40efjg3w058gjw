//
//  CMDrawable.m
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDrawable.h"

@interface CMDrawable ()

@property (nonatomic) KeyframeStore *keyframeStore;
@property (nonatomic) NSString *key;

@end

@implementation CMDrawable

- (instancetype)init {
    self = [super init];
    self.keyframeStore = [KeyframeStore new];
    self.boundsDiagonal = 100;
    self.key = [NSUUID UUID].UUIDString;
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    for (NSString *key in [self keysForCoding]) {
        [self setValue:[aDecoder decodeObjectForKey:key] forKey:key];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    for (NSString *key in [self keysForCoding]) {
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
    }
}

- (NSArray<NSString*>*)keysForCoding {
    return @[@"boundsDiagonal", @"keyframeStore", @"key"];
}

- (Class)keyframeClass {
    return [CMDrawableKeyframe class];
}

- (CMDrawableView *)renderToView:(CMDrawableView *)existingOrNil atTime:(FrameTime *)time {
    CMDrawableView *v = [existingOrNil isKindOfClass:[CMDrawableView class]] ? existingOrNil : [CMDrawableView new];
    CMDrawableKeyframe *keyframe = [self.keyframeStore interpolatedKeyframeAtTime:time];
    v.center = keyframe.center;
    v.bounds = CGRectMake(0, 0, self.boundsDiagonal / sqrt(2), self.boundsDiagonal / sqrt(2)); // TODO: is math
    v.alpha = keyframe.alpha;
    v.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(keyframe.rotation), keyframe.scale, keyframe.scale);
    return v;
}

@end

@implementation CMDrawableKeyframe

- (instancetype)init {
    self = [super init];
    self.center = CGPointMake(100, 100);
    self.alpha = 1;
    self.scale = 1;
    self.rotation = 0;
    return self;
}

- (NSArray<NSString*>*)keys {
    return @[@"center", @"scale", @"rotation", @"alpha", @"frameTime"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    for (NSString *key in [self keys]) {
        [self setValue:[aDecoder decodeObjectForKey:key] forKey:key];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    for (NSString *key in [self keys]) {
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
    }
}

- (instancetype)interpolatedWith:(id)other progress:(CGFloat)progress {
    CMDrawableKeyframe *i = [CMDrawableKeyframe new];
    for (NSString *key in [self keys]) {
        [i setValue:[[self valueForKey:key] interpolatedWith:[other valueForKey:key] progress:progress] forKey:key];
    }
    return i;
}

@end

@implementation CMDrawableView

@end
