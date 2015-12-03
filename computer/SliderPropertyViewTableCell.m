//
//  SliderPropertyViewTableCell.m
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "SliderPropertyViewTableCell.h"
#import "PropertyModel.h"

@interface SliderPropertyViewTableCell () {
    UISlider *_slider;
}

@end

@implementation SliderPropertyViewTableCell

- (void)setup {
    [super setup];
    _slider = [UISlider new];
    [self addSubview:_slider];
    [_slider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _slider.frame = CGRectMake(30, 0, self.bounds.size.width - 60, self.bounds.size.height);
}

- (void)reloadValue {
    [super reloadValue];
    _slider.minimumValue = self.model.valueMin;
    _slider.maximumValue = self.model.valueMax;
    _slider.value = [self.value floatValue];
}

- (void)valueChanged:(UISlider *)sender {
    [self saveValue:@([sender value])];
}

@end
