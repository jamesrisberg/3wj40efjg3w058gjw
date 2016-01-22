//
//  CanvasPosition.m
//  computer
//
//  Created by Nate Parrott on 12/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CanvasPosition.h"

@implementation CanvasPosition

- (instancetype)init {
    self = [super init];
    self.transform = CGAffineTransformIdentity;
    return self;
}

@end
