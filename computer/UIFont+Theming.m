//
//  UIFont+Theming.m
//  computer
//
//  Created by Nate Parrott on 1/22/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

#import "UIFont+Theming.h"

@implementation UIFont (Theming)

+ (NSString *)themeFontName {
    return @"ArialRoundedMTBold";
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"ArialRoundedMTBold" size:fontSize];
}

+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"ArialRoundedMTBold" size:fontSize];
}

@end
