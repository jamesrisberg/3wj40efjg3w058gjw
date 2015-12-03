//
//  StaticAnimationsPropertyTableViewCell.m
//  computer
//
//  Created by Nate Parrott on 12/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "StaticAnimationsPropertyTableViewCell.h"
#import "StaticAnimationPicker.h"

@interface StaticAnimationsPropertyTableViewCell ()

@property (nonatomic) StaticAnimationPicker *picker;

@end

@implementation StaticAnimationsPropertyTableViewCell

- (void)setup {
    [super setup];
    self.picker = [[StaticAnimationPicker alloc] initWithFrame:self.bounds];
    [self addSubview:self.picker];
    __weak StaticAnimationsPropertyTableViewCell *weakSelf = self;
    self.picker.animationDidChange = ^{
        [weakSelf saveValue:weakSelf.picker.animation];
    };
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.picker.frame = self.bounds;
}

- (void)reloadValue {
    [super reloadValue];
    self.picker.animation = self.value;
}

@end
