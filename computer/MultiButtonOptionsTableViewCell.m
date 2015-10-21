//
//  MultiButtonOptionsTableViewCell.m
//  computer
//
//  Created by Nate Parrott on 9/4/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "MultiButtonOptionsTableViewCell.h"
#import "ConvenienceCategories.h"

@interface MultiButtonOptionsTableViewCell ()

@property (nonatomic) NSArray *buttons;

@end

@implementation MultiButtonOptionsTableViewCell

- (void)setButtonTitles:(NSArray *)buttonTitles {
    _buttonTitles = buttonTitles;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    for (UIButton *b in self.buttons) [b removeFromSuperview];
    self.buttons = [buttonTitles map:^id(id obj) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b titleLabel].font = [UIFont boldSystemFontOfSize:self.textLabel.font.pointSize];
        [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [b setTitle:obj forState:UIControlStateNormal];
        [self addSubview:b];
        [b addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
        return b;
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSInteger i = 0;
    CGFloat buttonWidth = self.bounds.size.width / self.buttons.count;
    for (UIButton *b in self.buttons) {
        CGRect frame = CGRectMake(i * buttonWidth, 0, buttonWidth, self.bounds.size.height);
        frame = CGRectIntegral(frame);
        b.frame = frame;
        i++;
    }
}

- (void)tapped:(UIButton *)sender {
    void (^callback)() = self.buttonActions[[self.buttons indexOfObject:sender]];
    callback();
}

@end
