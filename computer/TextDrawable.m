//
//  TextDrawable.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "TextDrawable.h"
#import "UIFont+Sizing.h"
#import "TextEditorViewController.h"
#import "NSAttributedString+ResizeToFit.h"
#import <ReactiveCocoa.h>
#import "SliderOptionsCell.h"

@interface TextDrawable ()

@property (nonatomic) UILabel *label;

@property (nonatomic) NSAttributedString *fittedAttributedString;

@end

@implementation TextDrawable

- (void)setup {
    [super setup];
    self.label = [UILabel new];
    self.label.numberOfLines = 0;
    self.textEnd = 1;
    
    self.attributedString = [[self class] defaultAttributedStringWithText:NSLocalizedString(@"Double-tap to edit", @"")];
    [self addSubview:self.label];
    
    RAC(self.label, attributedText) = [RACSignal combineLatest:@[RACObserve(self, fittedAttributedString), RACObserve(self, textStart), RACObserve(self, textEnd)] reduce:^id(NSAttributedString *string, NSNumber *startNum, NSNumber *endNum){
        NSInteger startIndex = string.length * startNum.floatValue;
        NSInteger endIndex = string.length * endNum.floatValue;
        NSMutableAttributedString *blanked = string.mutableCopy;
        [blanked addAttribute:NSForegroundColorAttributeName value:[UIColor clearColor] range:NSMakeRange(0, startIndex)];
        [blanked addAttribute:NSForegroundColorAttributeName value:[UIColor clearColor] range:NSMakeRange(endIndex, blanked.length - endIndex)];
        return blanked;
    }];
}

+ (NSAttributedString *)defaultAttributedStringWithText:(NSString *)text {
    NSMutableParagraphStyle *para = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
    para.alignment = NSTextAlignmentCenter;
    NSDictionary *defaultAttrs = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:20], NSForegroundColorAttributeName: [UIColor blackColor], NSParagraphStyleAttributeName: para};
    return [[NSAttributedString alloc] initWithString:text attributes:defaultAttrs];
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
    _attributedString = attributedString;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = self.bounds;
    if (self.attributedString.length > 0) {
        self.fittedAttributedString = [self.attributedString resizeToFitInside:self.bounds.size];
    }
}

- (void)primaryEditAction {
    [self editText];
}

- (void)editText {
    TextEditorViewController *editor = [TextEditorViewController new];
    editor.text = self.attributedString;
    [editor setTextChanged:^(NSAttributedString *text) {
        self.attributedString = text;
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
    [[self vcForPresentingModals] presentViewController:nav animated:YES completion:nil];
}

- (UIViewController *)createInlineViewControllerForEditing {
    TextEditorViewController *editor = [TextEditorViewController new];
    editor.text = self.attributedString;
    [editor setTextChanged:^(NSAttributedString *text) {
        self.attributedString = text;
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
    return nav;
}

- (NSDictionary<__kindof NSString*, id>*)currentKeyframeProperties {
    NSMutableDictionary *d = [super currentKeyframeProperties].mutableCopy;
    d[@"textStart"] = @(self.textStart);
    d[@"textEnd"] = @(self.textEnd);
    return d;
}

- (void)setCurrentKeyframeProperties:(NSDictionary<__kindof NSString *,id> *)props {
    [super setCurrentKeyframeProperties:props];
    self.textStart = [props[@"textStart"] floatValue];
    self.textEnd = [props[@"textEnd"] floatValue];
}

- (NSArray<__kindof OptionsViewCellModel*>*)optionsViewCellModels {
    NSMutableArray *models = [super optionsViewCellModels].mutableCopy;
    
    __weak TextDrawable *weakSelf = self;
    
    OptionsViewCellModel *start = [OptionsViewCellModel new];
    start.title = NSLocalizedString(@"Text start", @"");
    start.cellClass = [SliderOptionsCell class];
    start.onCreate = ^(OptionsCell *cell) {
        SliderOptionsCell *slider = (id)cell;
        [slider setValue:weakSelf.textStart];
        slider.onValueChange = ^(CGFloat val) {
            weakSelf.textStart = val;
            [weakSelf updatedKeyframeProperties];
        };
    };
    
    OptionsViewCellModel *end = [OptionsViewCellModel new];
    end.title = NSLocalizedString(@"Text end", @"");
    end.cellClass = [SliderOptionsCell class];
    end.onCreate = ^(OptionsCell *cell) {
        SliderOptionsCell *slider = (id)cell;
        [slider setValue:weakSelf.textEnd];
        slider.onValueChange = ^(CGFloat val) {
            weakSelf.textEnd = val;
            [weakSelf updatedKeyframeProperties];
        };
    };
    
    return [models arrayByAddingObjectsFromArray:@[start, end]];
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.attributedString forKey:@"attributedText"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.attributedString = [[aDecoder decodeObjectForKey:@"attributedText"] hack_replaceAppleColorEmojiWithSystemFont];
    return self;
}

@end
