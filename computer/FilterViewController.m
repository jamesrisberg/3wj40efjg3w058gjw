//
//  FilterViewController.m
//  computer
//
//  Created by Nate Parrott on 9/8/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FilterViewController.h"
#import "ShowcaseFilterListController.h"

@interface FilterViewController ()

@end

@implementation FilterViewController

- (instancetype)initWithImage:(UIImage *)image callback:(void(^)(UIImage *filtered))callback {
    ShowcaseFilterListController *filterListVC = [[ShowcaseFilterListController alloc] initWithStyle:UITableViewStyleGrouped];
    filterListVC.image = image;
    filterListVC.callback = callback;
    self = [super initWithRootViewController:filterListVC];
    return self;
}

@end
