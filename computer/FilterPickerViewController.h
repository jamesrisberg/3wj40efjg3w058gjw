//
//  FilterPickerViewController.h
//  computer
//
//  Created by Nate Parrott on 11/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMMediaStore.h"
@class FilterPickerFilterInfo;

@interface FilterPickerViewController : UIViewController

+ (FilterPickerViewController *)filterPickerWithMediaID:(CMMediaID *)mediaID callback:(void(^)(CMMediaID *newMediaID))callback;
+ (FilterPickerViewController *)filterPickerWithImage:(UIImage *)image callback:(void(^)(UIImage *filtered))callback;
+ (FilterPickerViewController *)filterPickerWithImage:(UIImage *)image existingFilter:(FilterPickerFilterInfo *)filter callback:(void(^)(FilterPickerFilterInfo *newFilter))callback;

@property (nonatomic) NSArray<UIImage*> *snapshotsForImagePicker;

@end
