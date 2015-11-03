//
//  StrokePickerViewController.h
//  computer
//
//  Created by Nate Parrott on 11/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StrokePickerViewController : UIViewController

@property (nonatomic) CGFloat width;
@property (nonatomic) UIColor *color;
@property (nonatomic,copy) void(^onChange)(CGFloat width, UIColor *color);

@end
