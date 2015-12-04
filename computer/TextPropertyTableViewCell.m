//
//  TextPropertyTableViewCell.m
//  computer
//
//  Created by Nate Parrott on 12/4/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "TextPropertyTableViewCell.h"
#import "CMTextDrawable.h"
#import "TextEditorViewController.h"

@interface TextPropertyTableViewCell () {
    UITextView *_textView;
}

@end

@implementation TextPropertyTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    _textView = [UITextView new];
    [self.contentView addSubview:_textView];
    _textView.userInteractionEnabled = NO;
    _textView.layer.cornerRadius = 3;
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(edit)]];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _textView.frame = CGRectInset(self.bounds, [[self class] standardInlineControlPadding], [[self class] standardInlineControlPadding]);
}

- (void)reloadValue {
    [super reloadValue];
    _textView.attributedText = [(CMTextDrawable *)self.drawables.firstObject text];
}

- (void)edit {
    __weak TextPropertyTableViewCell *weakSelf = self;
    TextEditorViewController *editor = [[TextEditorViewController alloc] initWithNibName:@"TextEditorViewController" bundle:nil];
    editor.text = [(CMTextDrawable *)self.drawables.firstObject text];
    editor.textChanged = ^(NSAttributedString *text) {
        [weakSelf saveValue:text];
    };
    [[self viewControllerForModals] presentViewController:[[UINavigationController alloc] initWithRootViewController:editor] animated:YES completion:nil];
}

+ (CGFloat)heightForModel:(PropertyModel *)model {
    return 80;
}

@end
