//
//  SwipeMenuView.m
//  computer
//
//  Created by Nate Parrott on 11/18/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "SwipeMenuView.h"
#import "ConvenienceCategories.h"

@implementation SwipeMenuViewAction

@end


@interface SwipeMenuView ()

@property (nonatomic) NSArray *buttons;
@property (nonatomic) NSArray *labels;

@end

@implementation SwipeMenuView

- (void)setActions:(NSArray<__kindof SwipeMenuViewAction *> *)actions {
    _actions = actions;
    for (UIView *v in self.buttons) [v removeFromSuperview];
    for (UIView *v in self.labels) [v removeFromSuperview];
    
    self.buttons = [actions map:^id(id obj) {
        SwipeMenuViewAction *action = obj;
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b setImage:action.icon forState:UIControlStateNormal];
        [b addTarget:self action:@selector(tappedAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:b];
        return b;
    }];
    
    self.labels = [actions map:^id(id obj) {
        SwipeMenuViewAction *action = obj;
        UILabel *label = [UILabel new];
        label.font = [UIFont boldSystemFontOfSize:14];
        label.textColor = [UIColor whiteColor];
        label.text = action.title;
        [self addSubview:label];
        return label;
    }];
}

- (void)setView:(UIView *)view {
    [_view removeFromSuperview];
    _view = view;
    [self addSubview:view];
    
    self.showsHorizontalScrollIndicator = NO;
    self.pagingEnabled = YES;
    self.scrollsToTop = NO;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [self.view sizeThatFits:size];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.view.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    self.contentSize = CGSizeMake(self.bounds.size.width*2, self.bounds.size.height);
    CGSize actionSize = CGSizeMake(50, self.bounds.size.height);
    CGSize totalActionSize = CGSizeMake(actionSize.width * self.actions.count, actionSize.height);
    CGFloat x = self.bounds.size.width + (self.bounds.size.width - totalActionSize.width)/2;
    
    NSInteger i = 0;
    for (UIButton *button in self.buttons) {
        button.frame = CGRectMake(x, 0, actionSize.width, actionSize.height);
        x += actionSize.width;
        UILabel *label = self.labels[i++];
        [label sizeToFit];
        label.center = CGPointMake(button.center.x, self.bounds.size.height/2 + 30);
    }
}

- (void)tappedAction:(id)sender {
    SwipeMenuViewAction *action = self.actions[[self.buttons indexOfObject:sender]];
    action.action();
}

@end
