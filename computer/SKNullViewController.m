//
//  SKNullViewController.m
//  Sketch
//
//  Created by Nate Parrott on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SKNullViewController.h"

@interface SKNullViewController ()

@end

@implementation SKNullViewController
@synthesize message=_message;

-(void)setMessage:(NSString *)message {
    _message = message;
    _label.text = message;
    self.title = message;
}
-(void)loadView {
    self.view = [UIView new];
    _label = [[UILabel alloc] initWithFrame:self.view.bounds];
    _label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _label.textColor = [UIColor grayColor];
    _label.font = [UIFont systemFontOfSize:30];
    _label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_label];
    _label.text = self.message;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
