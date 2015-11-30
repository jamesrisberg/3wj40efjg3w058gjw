//
//  CMCanvas.m
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMCanvas.h"

@implementation CMCanvas

- (instancetype)init {
    self = [super init];
    self.drawables = [NSMutableArray new];
    return self;
}

@end
