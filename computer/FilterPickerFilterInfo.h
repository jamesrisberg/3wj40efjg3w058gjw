//
//  FilterPickerFilterInfo.h
//  computer
//
//  Created by Nate Parrott on 11/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage.h>

typedef NS_ENUM(NSInteger, FilterParameterType) {
    FilterParameterTypeFloat,
    FilterParameterTypeColor,
    FilterParameterTypePoint,
    FilterParameterTypeColorPickedFromImage
};

@interface FilterParameter : NSObject

@property (nonatomic) CGFloat min, max;
@property (nonatomic) NSString *key, *name;
@property (nonatomic) FilterParameterType type;

@end




@interface FilterPickerFilterInfo : NSObject

- (GPUImageOutput<GPUImageInput> *)createFilter;

+ (NSArray<__kindof FilterPickerFilterInfo*>*)allFilters;

@property (nonatomic,readonly) NSMutableArray<FilterParameter*> *parameters;
// convenience:
- (void)addSliderForKey:(NSString *)key min:(CGFloat)min max:(CGFloat)max name:(NSString *)name;
- (void)addColorPickerForKey:(NSString *)key name:(NSString *)name;
- (void)addPointPickerForKey:(NSString *)key name:(NSString *)name;
@property (nonatomic) NSString *name;
@property (nonatomic) BOOL showOnlyForVideo;
@property (nonatomic) BOOL hasSecondaryInput;
@property (nonatomic) NSString *customThumbnailImageName;

@end
