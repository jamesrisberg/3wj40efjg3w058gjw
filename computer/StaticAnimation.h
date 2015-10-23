//
//  StaticAnimation.h
//  computer
//
//  Created by Nate Parrott on 10/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVInterpolation.h"

@interface StaticAnimation : NSObject <NSCoding, EVInterpolation, NSCopying>

- (instancetype)init;

- (CGFloat)adjustAlpha:(CGFloat)oldAlpha time:(NSTimeInterval)time;
- (CGAffineTransform)adjustTransform:(CGAffineTransform)transform time:(NSTimeInterval)time;

@property (nonatomic) CGFloat blinkRate, blinkMagnitude;
@property (nonatomic) CGFloat fadeRate, fadeMagnitude;
@property (nonatomic) CGFloat pulseRate, pulseMagnitude;
@property (nonatomic) CGFloat jitterRate, jitterMagnitude;

- (BOOL)matchesAnimationDict:(NSDictionary *)dict;
- (void)addAnimationDict:(NSDictionary *)dict;
- (void)removeAnimationDict:(NSDictionary *)dict;

@end
