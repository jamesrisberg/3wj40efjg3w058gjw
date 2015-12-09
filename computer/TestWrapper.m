//
//  TestWrapper.m
//  computer
//
//  Created by Nate Parrott on 12/9/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "TestWrapper.h"

@implementation TestWrapper

- (void)setChild:(CMDrawableView *)child {
    if (child != _child) {
        [_child removeFromSuperview];
        _child = child;
        [self addSubview:child];
    }
    self.bounds = child.bounds;
    self.layer.borderWidth = 2;
    self.layer.borderColor = [UIColor purpleColor].CGColor;
}

- (instancetype)init {
    self = [super init];
    NSLog(@"init test wrapper");
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.child.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

@end
