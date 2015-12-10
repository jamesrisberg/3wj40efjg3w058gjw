//
//  FilterOptionsView.h
//  computer
//
//  Created by Nate Parrott on 11/26/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterPickerFilterInfo.h"
#import <GPUImage.h>

@interface FilterOptionsView : UIView

- (void)setFilter:(GPUImageOutput<GPUImageInput> *)filter info:(FilterPickerFilterInfo *)info;

@property (nonatomic) IBOutlet UISlider *mainSlider;
- (IBAction)mainSliderChanged:(id)sender;

@property (nonatomic,copy) void(^onChange)();
@property (nonatomic,copy) CGPoint(^transformPointIntoImageCoordinates)(CGPoint p);

@property (nonatomic) IBOutlet UIButton *action;
@property (nonatomic,copy) void(^onChangeSecondaryInputImage)(UIImage *image);

@property (nonatomic) NSArray<UIView*> *snapshotsForImagePicker;

@property (nonatomic,copy) void(^getColorAtPointBlock)(CGPoint pointInFilterOptionsView, void(^callback)(UIColor *color));

@end
