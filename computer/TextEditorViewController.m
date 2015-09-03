//
//  TextEditorViewController.m
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "TextEditorViewController.h"

@interface TextEditorViewController ()

@property (nonatomic) IBOutlet UITextView *textView;

@end

@implementation TextEditorViewController

- (NSString *)nibName {
    return @"TextEditorViewController";
}

- (void)setText:(NSString *)text {
    _text = text;
    [self loadViewIfNeeded];
    self.textView.text = text;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
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
    _text = self.textView.text;
    self.textChanged(self.textView.text);
}

@end
