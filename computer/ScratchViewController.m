//
//  ScratchViewController.m
//  computer
//
//  Created by Nate Parrott on 10/19/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ScratchViewController.h"
#import "TimelineView.h"
#import <ReactiveCocoa.h>
#import "CropView.h"

@interface ScratchViewController ()

@property (nonatomic) IBOutlet UILabel *label;
@property (nonatomic) IBOutlet CropView *cropView;

@end

@implementation ScratchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    TimelineView *timeline = [TimelineView new];
    [self.view addSubview:timeline];
    timeline.frame = CGRectMake(0, self.view.bounds.size.height - [TimelineView height], self.view.bounds.size.width, [TimelineView height]);
    timeline.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    RAC(self.label, text) = [RACObserve(timeline, time) map:^id(id value) {
        return [(NSNumber *)value stringValue];
    }];
    
    self.cropView.cropRect = CGRectMake(self.cropView.bounds.size.width/2 - 200/2, self.cropView.bounds.size.height/2 - 200/2, 200, 200);
}

@end
