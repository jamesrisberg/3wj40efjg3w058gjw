//
//  PropertiesViewTabControl.m
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "PropertiesViewTabControl.h"
#import "ConvenienceCategories.h"

@interface PropertiesViewTabControl () {
    NSArray *_buttons;
}

@end



@implementation PropertiesViewTabControl

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.showsHorizontalScrollIndicator = NO;
    return self;
}

- (void)setTabTitles:(NSArray<NSString *> *)tabTitles {
    _tabTitles = tabTitles;
    for (UIButton *old in _buttons) [old removeFromSuperview];
    _buttons = [tabTitles map:^id(id obj) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b setTitle:[obj uppercaseString] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [self addSubview:b];
        [b addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
        return b;
    }];
    self.highlightedTabIndex = self.highlightedTabIndex; // update it
}

- (void)setHighlightedTabIndex:(NSInteger)highlightedTabIndex {
    _highlightedTabIndex = highlightedTabIndex;
    NSInteger i = 0;
    for (UIButton *b in _buttons) {
        BOOL highlighted = (highlightedTabIndex == i++);
        b.alpha = highlighted ? 1 : 0.7;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat extraWidth = 20;
    CGFloat x = 0;
    for (UIButton *b in _buttons) {
        [b sizeToFit];
        b.frame = CGRectMake(x, 0, b.frame.size.width + extraWidth, self.bounds.size.height);
        x = CGRectGetMaxX(b.frame);
    }
    self.contentSize = CGSizeMake(x, self.bounds.size.height);
}

- (void)tapped:(UIButton *)sender {
    self.onTabSelected([_buttons indexOfObject:sender]);
}

@end
