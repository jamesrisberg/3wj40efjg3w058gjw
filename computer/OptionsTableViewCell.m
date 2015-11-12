//
//  OptionsTableViewCell.m
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "OptionsTableViewCell.h"
#import "OptionsCell.h"

@interface OptionsTableViewCell ()

@end

@implementation OptionsTableViewCell

- (void)setCell:(OptionsCell *)cell {
    [_cell removeFromSuperview];
    _cell = cell;
    [self addSubview:cell];
    self.backgroundColor = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.cell.frame = self.bounds;
}

- (UIColor *)highlightedBackgroundColor {
    return [UIColor colorWithWhite:1 alpha:0.5];
}

@end
