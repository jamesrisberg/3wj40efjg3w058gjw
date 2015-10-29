//
//  ExportTest.m
//  computer
//
//  Created by Nate Parrott on 10/28/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ExportTest.h"
#import "ANGifEncoder.h"
#import "ANGifNetscapeAppExtension.h"
#import "ANCutColorTable.h"
#import "ConvenienceCategories.h"
#import "UIImagePixelSource.h"
#import "computer-Swift.h"

@implementation ExportTest

+ (void)exportTestWithVC:(UIViewController *)vc {
    NSString *outputPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"test.gif"];
    NSLog(@"Exporting to %@", outputPath);
    NSArray *images = [[@"frame1 frame2 frame3 frame4" componentsSeparatedByString:@" "] map:^id(id obj) {
        return [UIImage imageNamed:obj];
    }];
    CGSize size = [images.firstObject size];
    ANGifEncoder *enc = [[ANGifEncoder alloc] initWithOutputFile:outputPath size:size globalColorTable:nil];
    
    ANGifNetscapeAppExtension *extension = [[ANGifNetscapeAppExtension alloc] init];
    [enc addApplicationExtension:extension];
    
    for (UIImage *image in images) {
        [enc addImageFrame:[self frameWithImage:image size:size delay:0.5]];
    }
    [enc closeFile];
    NSLog(@"done");
}

+ (ANGifImageFrame *)frameWithImage:(UIImage *)image size:(CGSize)size delay:(NSTimeInterval)delay {
    UIImage *scaledImage = image;
    if (!CGSizeEqualToSize(scaledImage.size, size)) {
        scaledImage = [image resizeTo:size];
    }
    
    UIImagePixelSource * pixelSource = [[UIImagePixelSource alloc] initWithImage:scaledImage];
    ANCutColorTable * colorTable = [[ANCutColorTable alloc] initWithTransparentFirst:YES pixelSource:pixelSource];
    ANGifImageFrame *frame = [[ANGifImageFrame alloc] initWithPixelSource:pixelSource colorTable:colorTable delayTime:delay];
    return frame;
}

@end
