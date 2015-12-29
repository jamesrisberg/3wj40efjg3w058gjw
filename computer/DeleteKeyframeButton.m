//
//  DeleteKeyframeButton.m
//  computer
//
//  Created by Nate Parrott on 12/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "DeleteKeyframeButton.h"

@interface DeleteKeyframeButton ()

@end



@implementation DeleteKeyframeButton

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, 24, 24)];
    
    UIVisualEffectView *fx = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    UIVisualEffectView *vibrancy = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:(UIBlurEffect *)fx.effect]];
    [self addSubview:fx];
    [fx.contentView addSubview:vibrancy];
    
    fx.frame = self.bounds;
    fx.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    vibrancy.frame = self.bounds;
    vibrancy.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"WhiteX"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.frame = self.bounds;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [vibrancy.contentView addSubview:imageView];
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
    
    self.clipsToBounds = YES;
    self.layer.cornerRadius = self.bounds.size.width/2;
    
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGFloat touchSize = 40;
    CGFloat inset = (self.bounds.size.width - touchSize)/2;
    return CGRectContainsPoint(CGRectInset(self.bounds, inset, inset), point);
}

- (void)tapped:(UITapGestureRecognizer *)rec {
    if (self.onPress) self.onPress();
}

@end
