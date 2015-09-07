//
//  Drawable.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"

@implementation Drawable

- (instancetype)init {
    self = [super init];
    [self setup];
    return self;
}

- (void)primaryEditAction {
    
}

- (void)setup {
    _rotation = 0;
    _scale = 1;
}

#pragma mark Transforms

- (void)setRotation:(CGFloat)rotation {
    _rotation = rotation;
    [self updateTransform];
}

- (void)setScale:(CGFloat)scale {
    _scale = scale;
    [self updateTransform];
}

- (void)updateTransform {
    self.transform = CGAffineTransformRotate(CGAffineTransformMakeScale(self.scale, self.scale), self.rotation);
}

#pragma mark Util

- (UIViewController *)vcForPresentingModals {
    return self.window.rootViewController;
}

- (Canvas *)canvas {
    return (Canvas *)self.superview;
}

#pragma mark Options

- (NSArray *)optionsCellModels {
    return @[];
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    // deliberately DON'T call super
    [aCoder encodeObject:[NSValue valueWithCGRect:self.bounds] forKey:@"bounds"];
    [aCoder encodeObject:[NSValue valueWithCGPoint:self.center] forKey:@"center"];
    [aCoder encodeDouble:self.scale forKey:@"scale"];
    [aCoder encodeDouble:self.rotation forKey:@"rotation"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithFrame:CGRectZero]; // deliberately DON'T call super
    self.bounds = [[aDecoder decodeObjectForKey:@"bounds"] CGRectValue];
    self.center = [[aDecoder decodeObjectForKey:@"center"] CGPointValue];
    self.scale = [aDecoder decodeDoubleForKey:@"scale"];
    self.rotation = [aDecoder decodeDoubleForKey:@"rotation"];
    return self;
}

@end
