//
//  SliderTableViewCell.h
//  computer
//
//  Created by Nate Parrott on 10/21/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "OptionsTableViewCell.h"

@interface SliderTableViewCell : OptionsTableViewCell

@property (nonatomic) CGFloat value; // 0-1
@property (nonatomic,copy) void (^onValueChange)(CGFloat val);

@end
