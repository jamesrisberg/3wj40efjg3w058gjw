//
//  FilterPickerViewController.h
//  computer
//
//  Created by Nate Parrott on 11/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CMMediaStore.h"

@interface FilterPickerViewController : UIViewController

+ (FilterPickerViewController *)filterPickerWithMediaID:(CMMediaID *)mediaID;
@property (nonatomic,copy) void(^callback)(CMMediaID *newMediaID);

@end
