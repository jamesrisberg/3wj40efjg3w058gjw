//
//  OptionsCell.h
//  computer
//
//  Created by Nate Parrott on 11/11/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Drawable;

@interface OptionsCell : UIView

@property (nonatomic) Drawable *drawable;
- (void)setup;
@property (nonatomic,readonly) UILabel *textLabel;

@end
