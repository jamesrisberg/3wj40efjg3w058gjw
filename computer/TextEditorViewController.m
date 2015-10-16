//
//  TextEditorViewController.m
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "TextEditorViewController.h"
#import "ConvenienceCategories.h"
#import "computer-Swift.h"
#import "CPColorPicker.h"
#import "SKFontPicker.h"

@interface _TextColorButton : UIButton
@end

@implementation _TextColorButton
- (void)setColor:(UIColor *)color {
    [self setImage:[[UIImage imageNamed:@"Pen"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.imageView.tintColor = color;
}
@end

@interface _TextFontButton : UIButton
@end

@implementation _TextFontButton
- (void)setTextFont:(UIFont *)font {
    [self setTitle:@"A" forState:UIControlStateNormal];
    self.titleLabel.font = [UIFont fontWithName:font.fontName size:16];
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}
@end

@interface _TextSizeButton : UIButton
@end

@implementation _TextSizeButton
- (void)setTextSize:(CGFloat)size {
    [self setTitle:[@(size) stringValue] forState:UIControlStateNormal];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}
@end

@interface TextEditorViewController () <UITextViewDelegate>

@property (nonatomic) IBOutlet UITextView *textView;

@property (nonatomic) _TextSizeButton *textSizeButton;
@property (nonatomic) _TextColorButton *textColorButton;
@property (nonatomic) _TextFontButton *textFontButton;

@end

@implementation TextEditorViewController

- (NSString *)nibName {
    return @"TextEditorViewController";
}

- (void)setText:(NSAttributedString *)text {
    [self loadViewIfNeeded];
    self.textView.attributedText = text;
    [self typingAttributesChanged];
}

- (NSAttributedString *)text {
    return self.textView.attributedText;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
    
    self.textSizeButton = [_TextSizeButton buttonWithType:UIButtonTypeCustom];
    [self.textSizeButton addTarget:self action:@selector(changeTextSize) forControlEvents:UIControlEventTouchUpInside];
    self.textColorButton = [_TextColorButton buttonWithType:UIButtonTypeCustom];
    [self.textColorButton addTarget:self action:@selector(changeTextColor) forControlEvents:UIControlEventTouchUpInside];
    self.textFontButton = [_TextFontButton buttonWithType:UIButtonTypeCustom];
    [self.textFontButton addTarget:self action:@selector(changeTextFont) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.leftBarButtonItems = [@[self.textColorButton, self.textSizeButton, self.textFontButton] map:^id(id obj) {
        UIButton *btn = obj;
        [btn setFrame:CGRectMake(0, 0, 40, 44)];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:obj];
        /*item.target = self;
        item.action = NSSelectorFromString([btn actionsForTarget:self forControlEvent:UIControlEventTouchUpInside].firstObject);
        btn.userInteractionEnabled = NO;*/
        item.width = 40;
        return item;
    }];
    [self typingAttributesChanged];
}

- (void)dismiss {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.textView becomeFirstResponder];
    self.textView.selectedRange = NSMakeRange(0, self.textView.text.length);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.textChanged(self.textView.attributedText);
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    [self typingAttributesChanged];
}

- (void)typingAttributesChanged {
    NSDictionary *attrs = self.textView.typingAttributes;
    [self.textSizeButton setTextSize:[attrs[NSFontAttributeName] pointSize]];
    [self.textFontButton setTextFont:attrs[NSFontAttributeName]];
    [self.textColorButton setColor:attrs[NSForegroundColorAttributeName]];
}

- (void)changeTextSize {
    
}

- (void)changeTextFont {
    SKFontPicker *picker = [[SKFontPicker alloc] init];
    picker.fontName = [self.textView.typingAttributes[NSFontAttributeName] fontName];
    [NPSoftModalPresentationController presentViewController:picker];
    __weak SKFontPicker *weakPicker = picker;
    picker.callback = ^(NSString *fontName) {
        [self updateTextEntryAttribute:NSFontAttributeName function:^id(id existing) {
            CGFloat pointSize = [existing pointSize] ? : 20;
            return [UIFont fontWithName:fontName size:pointSize];
        }];
        [weakPicker dismissViewControllerAnimated:YES completion:nil];
    };
}

- (void)changeTextColor {
    CPColorPicker *picker = [CPColorPicker new];
    picker.color = self.textView.typingAttributes[NSForegroundColorAttributeName];
    picker.callback = ^(UIColor *color) {
        [self updateTextEntryAttribute:NSForegroundColorAttributeName function:^id(id existing) {
            return color;
        }];
    };
    [NPSoftModalPresentationController presentViewController:picker];
}

- (void)updateTextEntryAttribute:(NSString *)attribute function:(id(^)(id existing))fn {
    // update the typing attributes:
    NSMutableDictionary *attrs = self.textView.typingAttributes.mutableCopy;
    id existing = attrs[attribute];
    id newVal = fn(existing);
    if (newVal) attrs[attribute] = newVal;
    else [attrs removeObjectForKey:attribute];
    self.textView.typingAttributes = attrs;
    [self typingAttributesChanged];
    
    // update selection:
    NSAttributedString *attributedText = self.textView.attributedText;
    // reset using a nil existing value, in case there are no existing values to enumerate:
    id newBaselineValue = fn(nil);
    if (newBaselineValue) {
        [self.textView.textStorage addAttribute:attribute value:newBaselineValue range:self.textView.selectedRange];
    } else {
        [self.textView.textStorage removeAttribute:attribute range:self.textView.selectedRange];
    }
    // transform existing values for this attribute:
    [attributedText enumerateAttribute:attribute inRange:self.textView.selectedRange options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        id newVal = fn(value);
        if (newVal) {
            [self.textView.textStorage addAttribute:attribute value:newVal range:range];
        } else {
            [self.textView.textStorage removeAttribute:attribute range:range];
        }
    }];
}

@end
