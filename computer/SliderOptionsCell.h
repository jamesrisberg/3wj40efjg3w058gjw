//
//  SliderTableViewCell.h
//  computer
//
//  Created by Nate Parrott on 10/21/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "OptionsCell.h"

@interface SliderOptionsCell : OptionsCell

@property (nonatomic) CGFloat value; // 0-1
@property (nonatomic,copy) void (^onValueChange)(CGFloat val);
@property (nonatomic,copy) void (^onTouchUp)();

- (CGFloat)getRampedValueWithMin:(CGFloat)min max:(CGFloat)max;
- (void)setRampedValue:(NSInteger)val withMin:(CGFloat)min max:(CGFloat)max;

@end
