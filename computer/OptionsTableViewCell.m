//
//  OptionsTableViewCell.m
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "OptionsTableViewCell.h"

@interface OptionsTableViewCell ()

@end

@implementation OptionsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    [self setup];
    return self;
}

- (void)setup {
    self.textLabel.textColor = [UIColor whiteColor];
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    UIColor *bgColor = highlighted ? [self highlightedBackgroundColor] : [UIColor clearColor];
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.backgroundColor = bgColor;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        self.backgroundColor = bgColor;
    }
}

- (UIColor *)highlightedBackgroundColor {
    return [UIColor colorWithWhite:1 alpha:0.5];
}

@end
