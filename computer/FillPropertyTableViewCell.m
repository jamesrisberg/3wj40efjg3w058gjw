//
//  FillPropertyTableViewCell.m
//  computer
//
//  Created by Nate Parrott on 12/4/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FillPropertyTableViewCell.h"
#import "computer-Swift.h"
#import "PropertyModel.h"

@interface FillPropertyTableViewCell ()

@property (nonatomic) PatternPickerView *picker;

@end

@implementation FillPropertyTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.picker = [PatternPickerView new];
    [self addSubview:self.picker];
    __weak FillPropertyTableViewCell *weakSelf = self;
    self.picker.onPatternChanged = ^(Pattern *pattern) {
        [weakSelf saveValue:pattern];
    };
    self.picker.shouldEditModally = ^{
        [weakSelf.picker editModally:[weakSelf viewControllerForModals]];
    };
    return self;
}

- (void)setModel:(PropertyModel *)model {
    [super setModel:model];
    self.picker.onlyAllowSolidColors = (model.type == PropertyModelTypeColor);
    self.picker.cell.label.text = (model.type == PropertyModelTypeColor) ? NSLocalizedString(@"Color", @"") : NSLocalizedString(@"Fill", @"");
}

- (void)reloadValue {
    [super reloadValue];
    self.picker.pattern = self.value;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _picker.frame = CGRectInset(self.bounds, [[self class] standardInlineControlPadding], [[self class] standardInlineControlPadding]);
}

+ (CGFloat)heightForModel:(PropertyModel *)model {
    return 44 + [[self class] standardInlineControlPadding] * 2;
}


@end
