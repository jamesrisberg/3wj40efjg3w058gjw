//
//  StaticAnimation.m
//  computer
//
//  Created by Nate Parrott on 10/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "StaticAnimation.h"
#import "CGPointExtras.h"

@interface StaticAnimation ()

@end

@implementation StaticAnimation

- (instancetype)init {
    self = [super init];
    _blinkRate = 1;
    _blinkMagnitude = 0;
    _fadeRate = 1;
    _fadeMagnitude = 0;
    _pulseRate = 1;
    _pulseMagnitude = 0;
    _jitterRate = 20;
    _jitterXMagnitude = 0;
    _jitterYMagnitude = 0;
    _rotationRate = 1;
    _rotationMagnitude = 0;
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    for (NSString *key in [self valuesToEncode]) {
        [self setValue:[aDecoder decodeObjectForKey:key] forKey:key];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    for (NSString *key in [self valuesToEncode]) {
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
    }
}

- (NSArray *)valuesToEncode {
    return @[@"blinkRate", @"blinkMagnitude", @"pulseRate", @"pulseMagnitude", @"jitterRate", @"jitterXMagnitude", @"jitterYMagnitude", @"fadeRate", @"fadeMagnitude", @"rotationRate", @"rotationMagnitude", @"wobbleRate", @"wobbleMagnitude"];
}

- (CGFloat)adjustAlpha:(CGFloat)alpha time:(NSTimeInterval)time {
    // compute blink:
    if (_blinkMagnitude) {
        CGFloat offness = cos(time * 2 * M_PI * _blinkRate) / 2 + 0.5; // from 0-1
        offness *= _blinkMagnitude / 2 + 0.5;
        if (offness > 0.5) {
            return 0;
        }
    }
    
    // compute fade:
    if (_fadeMagnitude) {
        CGFloat fade = sin(time * 2 * M_PI * _fadeRate) / 2 + 0.5;
        alpha *= (1 - fade * _fadeMagnitude);
    }
    
    return alpha;
}

- (CGAffineTransform)adjustTransform:(CGAffineTransform)t time:(NSTimeInterval)time {
    CGFloat scale = 1 + (_pulseMagnitude ? _pulseMagnitude * sin(time * _pulseRate * M_PI * 2) : 0);
    t = CGAffineTransformScale(t, scale, scale);
    CGFloat jitterX = _jitterXMagnitude ? _jitterXMagnitude * NPRandomContinuousFloat(time * _jitterRate) : 0;
    CGFloat jitterY = _jitterYMagnitude ? _jitterYMagnitude * NPRandomContinuousFloat(time * _jitterRate + 1000) : 0;
    t = CGAffineTransformTranslate(t, jitterX, jitterY);
    double integerPart;
    CGFloat rotate = _rotationMagnitude * modf(time * _rotationRate, &integerPart) * M_PI * 2;
    rotate += M_PI / 2 * sin(time * _wobbleRate * M_PI * 2) * _wobbleMagnitude;
    t = CGAffineTransformRotate(t, rotate);
    return t;
}

- (instancetype)interpolatedWith:(id)other progress:(CGFloat)progress {
    StaticAnimation *a = self;
    StaticAnimation *b = other;
    StaticAnimation *c = [StaticAnimation new];
#define INTERPOLATE_FLOAT(x) c.x = EVInterpolate(a.x, b.x, progress)
    INTERPOLATE_FLOAT(blinkMagnitude);
    INTERPOLATE_FLOAT(blinkRate);
    INTERPOLATE_FLOAT(fadeMagnitude);
    INTERPOLATE_FLOAT(fadeRate);
    INTERPOLATE_FLOAT(pulseMagnitude);
    INTERPOLATE_FLOAT(pulseRate);
    INTERPOLATE_FLOAT(jitterXMagnitude);
    INTERPOLATE_FLOAT(jitterYMagnitude);
    INTERPOLATE_FLOAT(jitterRate);
    INTERPOLATE_FLOAT(rotationMagnitude);
    INTERPOLATE_FLOAT(rotationRate);
    INTERPOLATE_FLOAT(wobbleRate);
    INTERPOLATE_FLOAT(wobbleMagnitude);
    return c;
}

#pragma mark Animation dictionaries


- (BOOL)matchesAnimationDict:(NSDictionary*)dict {
    for (NSString *key in dict) {
        if (![[self valueForKey:key] isEqual:dict[key]]) {
            return NO;
        }
    }
    return YES;
}

- (void)addAnimationDict:(NSDictionary*)dict {
    for (NSString *key in dict) {
        [self setValue:dict[key] forKey:key];
    }
}

- (void)removeAnimationDict:(NSDictionary *)dict {
    StaticAnimation *defaultAnim = [StaticAnimation new];
    for (NSString *key in dict) {
        [self setValue:[defaultAnim valueForKey:key] forKey:key];
    }
}

- (NSString *)description {
    NSMutableDictionary *d = [NSMutableDictionary new];
    for (NSString *key in [self valuesToEncode]) {
        d[key] = [self valueForKey:key];
    }
    return [NSString stringWithFormat:@"<StaticAnimation: %@>", d];
}

#pragma mark Copy

- (id)copy {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

@end
