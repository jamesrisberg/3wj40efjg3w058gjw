//
//  NSMutableArray+Utility.m
//  computer
//
//  Created by Nate Parrott on 12/9/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "NSMutableArray+Utility.h"

@implementation NSMutableArray (Utility)

- (id)pop {
    id item = [self lastObject];
    [self removeLastObject];
    return item;
}

@end
