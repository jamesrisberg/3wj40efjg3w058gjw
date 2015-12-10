//
//  GPUImageChromaKeyBlendFilter+GreenScreenColor.m
//  computer
//
//  Created by Nate Parrott on 12/10/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "GPUImageChromaKeyBlendFilter+GreenScreenColor.h"

@implementation GPUImageChromaKeyBlendFilter (GreenScreenColor)

- (UIColor * )greenScreenColor {
    return [UIColor blackColor]; // TODO: actually implement (is this possible?)
}

- (void)setGreenScreenColor:(UIColor *)greenScreenColor {
    CGFloat r, g, b;
    if (![greenScreenColor getRed:&r green:&g blue:&b alpha:nil]) {
        CGFloat white;
        [greenScreenColor getWhite:&white alpha:nil];
        r = g = b = white; // TODO: implement correctly
    }
    [self setColorToReplaceRed:r green:g blue:b];
}

@end
