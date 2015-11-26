//
//  FilterOptionsView.m
//  computer
//
//  Created by Nate Parrott on 11/26/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FilterOptionsView.h"
#import "ConvenienceCategories.h"

@interface FilterOptionsView ()

@property (nonatomic) FilterPickerFilterInfo *filterInfo;
@property (nonatomic) GPUImageOutput<GPUImageInput> *filter;

@property (nonatomic) FilterParameter *mainSliderParam;

@end

@implementation FilterOptionsView

- (void)setFilter:(GPUImageOutput<GPUImageInput> *)filter info:(FilterPickerFilterInfo *)info {
    _filter = filter;
    _filterInfo = info;
    
    NSMutableDictionary *paramsByType = [NSMutableDictionary new];
    for (FilterParameter *p in info.parameters) {
        if (!paramsByType[@(p.type)]) paramsByType[@(p.type)] = [NSMutableArray new];
        [paramsByType[@(p.type)] addObject:p];
    }
    
    self.mainSliderParam = [paramsByType[@(FilterParameterTypeFloat)] firstObject];
}

- (void)setMainSliderParam:(FilterParameter *)mainSliderParam {
    _mainSliderParam = mainSliderParam;
    self.mainSlider.hidden = !mainSliderParam;
    if (mainSliderParam) {
        self.mainSlider.minimumValue = mainSliderParam.min;
        self.mainSlider.maximumValue = mainSliderParam.max;
        self.mainSlider.value = [[self.filter valueForKey:mainSliderParam.key] floatValue];
    }
}

- (IBAction)mainSliderChanged:(id)sender {
    if (self.mainSliderParam) {
        [self.filter setValue:@(self.mainSlider.value) forKey:self.mainSliderParam.key];
        self.onChange();
    }
}

@end
