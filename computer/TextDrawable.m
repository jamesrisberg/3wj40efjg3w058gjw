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

@interface TextDrawable ()

@property (nonatomic) UILabel *label;

@end

@implementation TextDrawable

- (void)setup {
    [super setup];
    self.label = [UILabel new];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.text = @"Double-tap to change text";
    self.label.textColor = [UIColor blackColor];
    self.label.numberOfLines = 0;
    [self addSubview:self.label];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = self.bounds;
    if (self.label.text.length > 0) {
        self.label.font = [self.label.font fontWithSize:[self.label.font maximumPointSizeThatFitsText:self.label.text inSize:self.bounds.size]];
    }
}

- (void)primaryEditAction {
    TextEditorViewController *editor = [TextEditorViewController new];
    editor.text = self.label.text;
    [editor setTextChanged:^(NSString *text) {
        self.label.text = text;
        [self setNeedsLayout];
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
    [[self vcForPresentingModals] presentViewController:nav animated:YES completion:nil];
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.label.attributedText forKey:@"attributedText"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.label.attributedText = [aDecoder decodeObjectForKey:@"attributedText"];
    return self;
}

@end
