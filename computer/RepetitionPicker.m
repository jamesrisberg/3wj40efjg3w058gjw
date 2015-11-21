//
//  RepetitionPicker.m
//  computer
//
//  Created by Nate Parrott on 11/20/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "RepetitionPicker.h"
#import "SimplePickerViewController.h"

@implementation RepetitionPicker

+ (RepetitionPicker *)picker {
    RepetitionPicker *p = [RepetitionPicker buttonWithType:UIButtonTypeCustom];
    [p setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [p titleLabel].font = [UIFont boldSystemFontOfSize:14];
    [p addTarget:p action:@selector(change:) forControlEvents:UIControlEventTouchUpInside];
    return p;
}

- (void)setRebound:(BOOL)rebound {
    _rebound = rebound;
    [self update];
}

- (void)setRepeatCount:(NSInteger)repeatCount {
    _repeatCount = repeatCount;
    [self update];
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(70, 44);
}

- (void)update {
    [self setTitle:[self stringForRepeatCount:self.repeatCount rebound:self.rebound] forState:UIControlStateNormal];
}

- (NSString *)stringForRepeatCount:(NSInteger)count rebound:(BOOL)rebound {
    return [NSString stringWithFormat:@"%@x %@", @(count), (rebound ? @"↻↺" : @"↻")];
}

- (void)change:(id)sender {
    NSMutableArray *models = [NSMutableArray new];
    SimplePickerModel *selected = nil;
    for (NSInteger repeat=1; repeat < 10; repeat++) {
        for (NSInteger rebound=0; rebound<=1; rebound++) {
            SimplePickerModel *model = [SimplePickerModel new];
            model.title = [self stringForRepeatCount:repeat rebound:!!rebound];
            model.userInfo = @{@"repeat": @(repeat), @"rebound": @(!!rebound)};
            [models addObject:model];
            if (repeat == self.repeatCount && !!rebound == self.rebound) {
                selected = model;
            }
        }
    }
    SimplePickerViewController *picker = [SimplePickerViewController picker];
    picker.models = models;
    picker.selectedModel = selected;
    [picker presentWithCallback:^(SimplePickerModel *modelOrNil) {
        if (modelOrNil) {
            self.repeatCount = [modelOrNil.userInfo[@"repeat"] integerValue];
            self.rebound = [modelOrNil.userInfo[@"rebound"] boolValue];
        }
    }];
}

@end
