//
//  FilterPickerFilterInfo.m
//  computer
//
//  Created by Nate Parrott on 11/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FilterPickerFilterInfo.h"

@interface FilterPickerFilterInfo ()

@property (nonatomic,copy) GPUImageFilter*(^filterBlock)();

@end

@implementation FilterPickerFilterInfo

+ (NSArray<__kindof FilterPickerFilterInfo*>*)allFilters {
    FilterPickerFilterInfo *noFilter = [FilterPickerFilterInfo new];
    [noFilter setFilterBlock:^GPUImageFilter *{
        return [GPUImageFilter new];
    }];
    
    FilterPickerFilterInfo *brightness = [FilterPickerFilterInfo new];
    [brightness setFilterBlock:^GPUImageFilter *{
        GPUImageBrightnessFilter *f = [GPUImageBrightnessFilter new];
        f.brightness = 0.67;
        return f;
    }];
    
    FilterPickerFilterInfo *sat = [FilterPickerFilterInfo new];
    [sat setFilterBlock:^GPUImageFilter *{
        GPUImageSaturationFilter *s = [GPUImageSaturationFilter new];
        s.saturation = 0;
        return s;
    }];
    
    FilterPickerFilterInfo *blur = [FilterPickerFilterInfo new];
    [blur setFilterBlock:^GPUImageFilter *{
        return [GPUImageGaussianBlurFilter new];
    }];
    
    FilterPickerFilterInfo *toon = [FilterPickerFilterInfo new];
    [toon setFilterBlock:^GPUImageFilter *{
        return [GPUImageToonFilter new];
    }];
    
    FilterPickerFilterInfo *pixellate = [FilterPickerFilterInfo new];
    [pixellate setFilterBlock:^GPUImageFilter *{
        GPUImagePixellateFilter *pix = [GPUImagePixellateFilter new];
        return pix;
    }];
    
    return @[noFilter, brightness, sat, blur, toon, pixellate];
}

- (GPUImageFilter *)createFilter {
    return self.filterBlock();
}

@end
