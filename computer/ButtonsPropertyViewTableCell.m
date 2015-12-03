//
//  ButtonsPropertyViewTableCell.m
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ButtonsPropertyViewTableCell.h"
#import "PropertyModel.h"
#import "ConvenienceCategories.h"

@interface ButtonsPropertyViewTableCell ()

@property (nonatomic) NSArray *buttons;

@end

@implementation ButtonsPropertyViewTableCell

- (void)setModel:(PropertyModel *)model {
    [super setModel:model];
    self.buttons = [model.buttonTitles map:^id(id obj) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b setTitle:obj forState:UIControlStateNormal];
        [b setTitleColor:[UIColor colorWithWhite:1 alpha:0.3] forState:UIControlStateDisabled];
        [b addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
        return b;
    }];
}

- (void)setButtons:(NSArray *)buttons {
    for (UIButton *b in _buttons) [b removeFromSuperview];
    _buttons = buttons;
    for (UIButton *b in self.buttons) [self.contentView addSubview:b];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat buttonWidth = self.bounds.size.width / self.buttons.count;
    CGFloat x = 0;
    for (UIButton *b in self.buttons) {
        b.frame = CGRectMake(x, 0, buttonWidth, self.bounds.size.height);
        x = CGRectGetMaxX(b.frame);
    }
}

- (void)reloadValue {
    [super reloadValue];
    
    NSInteger i = 0;
    for (UIButton *b in self.buttons) {
        NSString *availabilitySelectorName = self.model.availabilitySelectors[i++];
        b.enabled = (availabilitySelectorName == nil || [[(NSObject *)self.drawables.firstObject performSelector:NSSelectorFromString(availabilitySelectorName) withObject:self] boolValue]);
    }
}

- (void)tapped:(UIButton *)sender {
    NSInteger index = [self.buttons indexOfObject:sender];
    [(NSObject *)self.drawables.firstObject performSelector:NSSelectorFromString(self.model.buttonSelectorNames[index]) withObject:self];
}

@end
