//
//  UIColor+RandomColors.m
//  computer
//
//  Created by Nate Parrott on 11/23/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "UIColor+RandomColors.h"
#import <Chameleon.h>

@implementation UIColor (RandomColors)

+ (UIColor *)randomHue {
    // return [UIColor colorWithRandomFlatColorOfShadeStyle:UIShadeStyleDark];
    return [UIColor colorWithHue:(rand() % 1000) / 1000.0 saturation:1 brightness:1 alpha:1];
}

@end
