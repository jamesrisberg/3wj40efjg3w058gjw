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
#import "StrokePickerViewController.h"
#import "UIBarButtonItem+BorderedButton.h"

@interface TextEditorViewController () <UITextViewDelegate> {
}

@property (nonatomic) IBOutlet UITextView *textView;

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
    
    UIButton *font = [UIButton buttonWithType:UIButtonTypeCustom];
    [font setTitle:NSLocalizedString(@"Font", @"").uppercaseString forState:UIControlStateNormal];
    [font addTarget:self action:@selector(changeTextFont) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *color = [UIButton buttonWithType:UIButtonTypeCustom];
    [color setTitle:NSLocalizedString(@"Color", @"").uppercaseString forState:UIControlStateNormal];
    [color addTarget:self action:@selector(changeTextColor) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *shadow = [UIButton buttonWithType:UIButtonTypeCustom];
    [shadow setTitle:NSLocalizedString(@"Shadow", @"").uppercaseString forState:UIControlStateNormal];
    [shadow addTarget:self action:@selector(changeTextShadow) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.leftBarButtonItems = [@[font, color, shadow] map:^id(id obj) {
        UIButton *b = obj;
        [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:[b titleForState:UIControlStateNormal] attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:14], NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
        [b setAttributedTitle:title forState:UIControlStateNormal];
        [b sizeToFit];
        return [[UIBarButtonItem alloc] initWithCustomView:b];
    }];
    
    /*self.navigationItem.leftBarButtonItems = @[
                                               [[UIBarButtonItem alloc] initUnborderedWithTitle:NSLocalizedString(@"Font", @"") target:self action:@selector(changeTextFont)],
                                               [[UIBarButtonItem alloc] initUnborderedWithTitle:NSLocalizedString(@"Color", @"") target:self action:@selector(changeTextColor)],
                                               [[UIBarButtonItem alloc] initUnborderedWithTitle:NSLocalizedString(@"Shadow", @"") target:self action:@selector(changeTextShadow)],
                                               ];*/
    self.navigationItem.leftItemsSupplementBackButton = YES;
    [self typingAttributesChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.textView becomeFirstResponder];
    self.textView.selectedRange = NSMakeRange(0, self.textView.text.length);
}

- (void)dismiss {
    self.textChanged(self.textView.attributedText);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)textViewDidChange:(UITextView *)textView {
    
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    // self.textChanged(self.textView.attributedText);
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    [self typingAttributesChanged];
}

- (void)typingAttributesChanged {
    CGFloat val = 0;
    UIColor *color = self.textView.typingAttributes[NSForegroundColorAttributeName];
    if (color) {
        if (![color getHue:nil saturation:nil brightness:&val alpha:nil] && ![color getWhite:&val alpha:nil]) {
            val = 0;
        }
    }
    self.textView.backgroundColor = val > 0.65 ? [UIColor blackColor] : [UIColor whiteColor];
}

- (void)changeTextSize {
    // TODO
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

- (void)changeTextShadow {
    StrokePickerViewController *picker = [StrokePickerViewController new];
    NSShadow *shadow = self.textView.typingAttributes[NSShadowAttributeName];
    picker.width = shadow.shadowOffset.width;
    picker.color = shadow.shadowColor ? : [UIColor colorWithWhite:0.1 alpha:0.5];
    [picker strokeWidthSlider].maximumValue = 10;
    picker.defaultStrokeWidthValue = 2;
    [NPSoftModalPresentationController presentViewController:picker];
    picker.onChange = ^(CGFloat offset, UIColor *color) {
        [self updateTextEntryAttribute:NSShadowAttributeName function:^id(id existing) {
            if (offset == 0) {
                return nil;
            }
            NSShadow *shadow = [[NSShadow alloc] init];
            shadow.shadowColor = color;
            shadow.shadowOffset = CGSizeMake(offset, offset);
            shadow.shadowBlurRadius = 0;
            return shadow;
        }];
        
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
    NSRange range = self.textView.selectedRange.length ? self.textView.selectedRange : NSMakeRange(0, self.textView.text.length);
    if (newBaselineValue) {
        [self.textView.textStorage addAttribute:attribute value:newBaselineValue range:range];
    } else {
        [self.textView.textStorage removeAttribute:attribute range:range];
    }
    // transform existing values for this attribute:
    [attributedText enumerateAttribute:attribute inRange:range options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        id newVal = fn(value);
        if (newVal) {
            [self.textView.textStorage addAttribute:attribute value:newVal range:range];
        } else {
            [self.textView.textStorage removeAttribute:attribute range:range];
        }
    }];
    
    // self.textChanged(self.textView.attributedText);
}

@end
