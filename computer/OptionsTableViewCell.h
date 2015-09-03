//
//  OptionsTableViewCell.h
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Drawable.h"

@interface OptionsTableViewCell : UITableViewCell

@property (nonatomic) Drawable *drawable;
- (void)setup;

@end
