//
//  CMRepeatingWrapper.m
//  computer
//
//  Created by Nate Parrott on 12/9/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMRepeatingWrapper.h"

@implementation CMRepeatingWrapper

- (void)setChild:(CMDrawableView *)child {
    if (child != _child) {
        [_child removeFromSuperview];
        _child = child;
        [self addSubview:child];
    }
    
    CGSize size = child.bounds.size;
    if (_vertical) {
        size.height += (_count - 1) * child.bounds.size.height * _gap;
    } else {
        size.width += (_count - 1) * child.bounds.size.width * _gap;
    }
    
    self.bounds = CGRectMake(0, 0, size.width, size.height);
    child.center = CGPointMake(child.bounds.size.width/2, child.bounds.size.height/2);
    
    CAReplicatorLayer *repl = (id)self.layer;
    repl.instanceCount = _count;
    CGSize translation = CGSizeZero;
    if (_vertical) {
        translation.height = child.bounds.size.height * _gap;
    } else {
        translation.width = child.bounds.size.width * _gap;
    }
    repl.instanceTransform = CATransform3DMakeTranslation(translation.width, translation.height, 0);
}

+ (Class)layerClass {
    return [CAReplicatorLayer class];
}

@end
