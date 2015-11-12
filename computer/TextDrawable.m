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

@interface TextDrawable ()

@property (nonatomic) UILabel *label;
@property (nonatomic) NSAttributedString *attributedString;

@end

@implementation TextDrawable

- (void)setup {
    [super setup];
    self.label = [UILabel new];
    self.label.numberOfLines = 0;
    
    NSMutableParagraphStyle *para = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
    NSDictionary *defaultAttrs = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:20], NSForegroundColorAttributeName: [UIColor blackColor], NSParagraphStyleAttributeName: para};
    self.attributedString = [[NSAttributedString alloc] initWithString:@"Double-tap for options" attributes:defaultAttrs];
    [self addSubview:self.label];
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
    _attributedString = attributedString;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = self.bounds;
    if (self.attributedString.length > 0) {
        self.label.attributedText = [self.attributedString resizeToFitInside:self.bounds.size];
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

- (NSArray <__kindof QuickCollectionItem*> *)optionsItems {
    __weak TextDrawable *weakSelf = self;
    
    QuickCollectionItem *editText = [QuickCollectionItem new];
    editText.label = NSLocalizedString(@"Edit text…", @"");
    editText.action = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf editText];
        });
    };
    
    return [[super optionsItems] arrayByAddingObjectsFromArray:@[editText]];
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
