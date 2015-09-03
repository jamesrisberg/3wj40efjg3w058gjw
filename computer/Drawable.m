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

@end
