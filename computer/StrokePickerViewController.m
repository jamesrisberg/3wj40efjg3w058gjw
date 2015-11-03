//
//  StrokePickerViewController.m
//  computer
//
//  Created by Nate Parrott on 11/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "StrokePickerViewController.h"
#import "CPColorPicker.h"

@interface StrokePickerViewController ()

@property (nonatomic) CPColorPicker *colorPicker;
@property (nonatomic) UISlider *slider;

@end

@implementation StrokePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.colorPicker = [CPColorPicker new];
    __weak StrokePickerViewController *weakSelf = self;
    self.colorPicker.callback = ^(UIColor *color) {
        StrokePickerViewController *strongSelf = weakSelf;
        strongSelf->_color = color;
        [weakSelf didUpdate];
    };
    [self addChildViewController:self.colorPicker];
    [self.view addSubview:self.colorPicker.view];
    
    self.slider = [[UISlider alloc] init];
    self.slider.minimumValue = 0;
    self.slider.maximumValue = 40;
    [self.slider addTarget:self action:@selector(widthChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.slider];
    
    self.view.backgroundColor = self.colorPicker.view.backgroundColor;
    
    [self updatePreview];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sliderHeight = 40;
    self.colorPicker.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - sliderHeight);
    self.slider.frame = CGRectMake(20, self.view.bounds.size.height - sliderHeight + (sliderHeight - self.slider.frame.size.height)/2, self.view.bounds.size.width - 40, self.slider.frame.size.height);
}

- (void)widthChanged {
    _width = round(self.slider.value);
    [self didUpdate];
}

- (void)didUpdate {
    if (self.onChange) self.onChange(self.width, self.color);
    [self updatePreview];
}

- (void)updatePreview {
    self.colorPicker.colorPreviewHeight = self.width;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self view];
    self.colorPicker.color = color;
    [self updatePreview];
}

- (void)setWidth:(CGFloat)width {
    _width = width;
    [self view];
    self.slider.value = width;
    [self updatePreview];
}

@end
