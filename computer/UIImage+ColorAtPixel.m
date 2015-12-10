//
//  UIImage+ColorAtPixel.m
//  computer
//
//  Created by Nate Parrott on 12/10/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

// via someone on stackoverflow but it was literally wrong wtf

#import "UIImage+ColorAtPixel.h"

@implementation UIImage (ColorAtPixel)

+ (NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)x andY:(int)y count:(int)count
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
    for (int i = 0 ; i < count ; ++i)
    {
        CGFloat alpha = ((CGFloat) rawData[byteIndex + 3] ) / 255.0f;
        CGFloat red   = ((CGFloat) rawData[byteIndex]     ) / alpha / 255.0;
        CGFloat green = ((CGFloat) rawData[byteIndex + 1] ) / alpha / 255.0;
        CGFloat blue  = ((CGFloat) rawData[byteIndex + 2] ) / alpha / 255.0;
        byteIndex += bytesPerPixel;
        
        UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [result addObject:acolor];
    }
    
    free(rawData);
    
    return result;
}

- (UIColor *)colorAtPixel:(CGPoint)p {
    int x = MAX(0, MIN(self.size.width-1, p.x));
    int y = MAX(0, MIN(self.size.height-1, p.y));
    return [[self class] getRGBAsFromImage:self atX:x andY:y count:1].firstObject;
}

@end
