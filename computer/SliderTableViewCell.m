//
//  SliderTableViewCell.m
//  computer
//
//  Created by Nate Parrott on 10/21/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "SliderTableViewCell.h"

@interface SliderTableViewCell ()

@property (nonatomic) UISlider *slider;

@end

@implementation SliderTableViewCell

- (void)setup {
    [super setup];
    self.slider = [UISlider new];
    self.slider.minimumValue = 0;
    self.slider.maximumValue = 1;
    [self addSubview:self.slider];
    [self.slider addTarget:self action:@selector(changedValue) forControlEvents:UIControlEventValueChanged];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat height = [self.slider intrinsicContentSize].height;
    self.slider.frame = CGRectMake(40, (self.bounds.size.height - height)/2, self.bounds.size.width - 40*2, height);
}

- (void)changedValue {
    if (self.onValueChange) {
        self.onValueChange(self.value);
    }
}

- (void)setValue:(CGFloat)value {
    self.slider.value = value;
}

- (CGFloat)value {
    return self.slider.value;
}

@end
