//
//  ExpandingButton.m
//  computer
//
//  Created by Nate Parrott on 10/1/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ExpandingButton.h"

@interface ExpandingButton ()

@property (nonatomic) UIImageView *glyph;

@end

@implementation ExpandingButton

- (instancetype)initWithBackground:(UIImage *)background glpyh:(UIImage *)glyph {
    self = [super init];
    [self setImage:background forState:UIControlStateNormal];
    CGFloat padding = 15;
    [self setContentEdgeInsets:UIEdgeInsetsMake(padding, padding, padding, padding)];
    self.bounds = CGRectMake(0, 0, background.size.width + padding*2, background.size.height + padding*2);
    self.glyph = [[UIImageView alloc] initWithImage:glyph];
    self.adjustsImageWhenHighlighted = NO;
    [self addSubview:self.glyph];
    [self.glyph sizeToFit];
    self.glyph.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.glyph.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    CGFloat scale = highlighted ? 2 : 1;
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformMakeScale(scale, scale);
        self.glyph.transform = CGAffineTransformMakeScale(1 / scale, 1 / scale);
        self.alpha = highlighted ? 0.5 : 1;
    } completion:^(BOOL finished) {
        
    }];
}

@end
