//
//  InlineViewControllerCollectionViewCell.m
//  computer
//
//  Created by Nate Parrott on 11/11/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "InlineViewControllerCollectionViewCell.h"

@interface InlineViewControllerCollectionViewCell ()

@property (nonatomic) UIViewController *inlineVC;

@end

@implementation InlineViewControllerCollectionViewCell

- (void)setViewController:(UIViewController *)vc parentViewController:(UIViewController *)parent {
    [self.inlineVC removeFromParentViewController];
    [self.inlineVC.view removeFromSuperview];
    
    self.inlineVC = vc;
    [parent addChildViewController:self.inlineVC];
    [self.contentView addSubview:self.inlineVC.view];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.inlineVC.view.frame = self.bounds;
}

@end
