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

@interface EditorViewController ()

@property (nonatomic) UIVisualEffectView *toolbar;
@property (nonatomic) IconBar *iconBar;

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
}

#pragma mark Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.canvas.frame = self.view.bounds;
    self.toolbar.frame = CGRectMake(0, self.view.bounds.size.height-44, self.view.bounds.size.width, 44);
    self.iconBar.frame = self.toolbar.bounds;
}

@end
