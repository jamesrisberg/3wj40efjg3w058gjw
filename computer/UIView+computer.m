//
//  UIView+computer.m
//  computer
//
//  Created by Nate Parrott on 9/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "UIView+computer.h"

@implementation UIView (computer)

- (void)replaceWith:(UIView *)replacement {
    UIView *superview = self.superview;
    NSInteger index = [self.superview.subviews indexOfObject:replacement];
    [self removeFromSuperview];
    [superview insertSubview:replacement atIndex:index];
}

@end
