//
//  OptionsCollectionViewCell.m
//  computer
//
//  Created by Nate Parrott on 11/11/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "OptionsCollectionViewCell.h"
#import "OptionsCell.h"

@interface OptionsCollectionViewCell ()

@property (nonatomic) UILabel *titleLabel;

@end

@implementation OptionsCollectionViewCell

- (void)setCell:(OptionsCell *)cell {
    [_cell removeFromSuperview];
    _cell = cell;
    [self.contentView addSubview:cell];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat titleHeight = self.titleLabel ? 20 : 0;
    self.cell.frame = CGRectMake(0, titleHeight, self.bounds.size.width, self.bounds.size.height - titleHeight);
    self.titleLabel.frame = CGRectMake(0, 0, self.bounds.size.width, titleHeight);
}

- (void)setTitle:(NSString *)title {
    _title = title;
    if (title) {
        if (!self.titleLabel) {
            self.titleLabel = [UILabel new];
            self.titleLabel.textColor = [UIColor whiteColor];
            self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
            [self.contentView addSubview:self.titleLabel];
        }
        self.titleLabel.text = title.uppercaseString;
    } else {
        if (self.titleLabel) {
            [self.titleLabel removeFromSuperview];
            self.titleLabel = nil;
        }
    }
}

@end
