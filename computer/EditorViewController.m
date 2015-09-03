//
//  EditorViewController.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EditorViewController.h"
#import "Canvas.h"
#import "IconBar.h"
#import "Drawable.h"

@interface EditorViewController ()

@property (nonatomic) UIVisualEffectView *toolbar;
@property (nonatomic) IconBar *iconBar;
@property (nonatomic) UIView *selectionRect;

@end

@implementation EditorViewController

#pragma mark Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    self.canvas = [Canvas new];
    [self.view addSubview:self.canvas];
    self.toolbar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    [self.view addSubview:self.toolbar];
    self.iconBar = [IconBar new];
    self.iconBar.editor = self;
    [self.toolbar addSubview:self.iconBar];
    __weak EditorViewController *weakSelf = self;
    self.canvas.selectionRectNeedUpdate = ^{
        [weakSelf updateSelectionRect];
    };
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.canvas.frame = self.view.bounds;
    self.toolbar.frame = CGRectMake(0, self.view.bounds.size.height-44, self.view.bounds.size.width, 44);
    self.iconBar.frame = self.toolbar.bounds;
}

- (void)updateSelectionRect {
    if (!self.selectionRect) {
        self.selectionRect = [UIView new];
        self.selectionRect.userInteractionEnabled = NO;
        self.selectionRect.layer.borderColor = [UIColor colorWithRed:1 green:0.1 blue:0.1 alpha:0.5].CGColor;
        self.selectionRect.layer.borderWidth = 1;
        [self.view insertSubview:self.selectionRect aboveSubview:self.canvas];
    }
    self.selectionRect.hidden = (self.canvas.selection == nil);
    if (self.canvas.selection) {
        Drawable *selection = self.canvas.selection;
        self.selectionRect.bounds = CGRectMake(0, 0, selection.bounds.size.width * selection.scale, selection.bounds.size.height * selection.scale);
        self.selectionRect.center = [self.view convertPoint:selection.center fromView:selection.superview];
        self.selectionRect.transform = CGAffineTransformMakeRotation(selection.rotation);
    }
}

@end
