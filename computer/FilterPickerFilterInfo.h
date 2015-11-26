//
//  FilterPickerFilterInfo.h
//  computer
//
//  Created by Nate Parrott on 11/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage.h>

@interface FilterPickerFilterInfo : NSObject

- (GPUImageFilter *)createFilter;

+ (NSArray<__kindof FilterPickerFilterInfo*>*)allFilters;

@end
