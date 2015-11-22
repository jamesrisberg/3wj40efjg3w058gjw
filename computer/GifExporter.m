//
//  GifExporter.m
//  computer
//
//  Created by Nate Parrott on 11/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "GifExporter.h"
#import "ANGifEncoder.h"
#import "ANGifNetscapeAppExtension.h"
#import "ANCutColorTable.h"
#import "ConvenienceCategories.h"
#import "UIImagePixelSource.h"
#import "computer-Swift.h"
#import "GifOptimizer.h"
#import "VideoConstants.h"
#import "Keyframe.h"
#import "EditorViewController+Send.h"

@implementation GifExporter

- (void)start {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"export.gif"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        NSLog(@"Writing gif to %@", path);
        
        CGSize size = self.cropRect.size;
        size.width *= [UIScreen mainScreen].scale;
        size.height *= [UIScreen mainScreen].scale;
        CGFloat maxDimension = 500;
        CGFloat scale = MIN(1, MIN(maxDimension / size.width, maxDimension / size.height));
        size.width = round(size.width * scale);
        size.height = round(size.height * scale);
        NSInteger fps = VC_GIF_FPS;
        self.fps = fps;
        
        ANGifEncoder *enc = [[ANGifEncoder alloc] initWithOutputFile:path size:size globalColorTable:nil];
        
        // enable looping:
        ANGifNetscapeAppExtension *extension = [[ANGifNetscapeAppExtension alloc] init];
        [enc addApplicationExtension:extension];
        
        [self enumerateFrameTimes:^(FrameTime *time) {
            UIImage *frameImage = [self renderFrameAtTime:time size:size];
            ANGifImageFrame *frame = [self frameWithImage:frameImage size:size delay:1.0 / fps];
            [enc addImageFrame:frame];
        }];
        
        [enc closeFile];
        
        NSLog(@"starting to optimize");
        [GifOptimizer optimizeGifAtPath:path doneBlock:^{
            NSLog(@"done");
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL *gifURL = [NSURL fileURLWithPath:path];
                
                UIAlertController *actions = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Share GIF", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                if ([MFMessageComposeViewController canSendAttachments]) {
                    [actions addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send as Message", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        MFMessageComposeViewController *compose = [MFMessageComposeViewController new];
                        [compose addAttachmentURL:gifURL withAlternateFilename:@"Content.gif"];
                        [self.parentViewController presentMessageComposer:compose];
                    }]];
                }
                if ([MFMailComposeViewController canSendMail]) {
                    [actions addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send in Email", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        MFMailComposeViewController *compose = [MFMailComposeViewController new];
                        [compose addAttachmentData:[NSData dataWithContentsOfURL:gifURL] mimeType:@"image/gif" fileName:@"Content.gif"];
                        [self.parentViewController presentMailComposer:compose];
                    }]];
                }
                [actions addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Share Link to GIF", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                }]];
                [actions addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Never mind", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                }]];
                [self.parentViewController presentViewController:actions animated:YES completion:nil];
                
                [self done];
            });
        }];
    });
}

- (void)done {
    // TODO: delete the temp file?
    [self.delegate exporterDidFinish:self];
}

- (ANGifImageFrame *)frameWithImage:(UIImage *)image size:(CGSize)size delay:(NSTimeInterval)delay {
    UIImage *scaledImage = image;
    if (!CGSizeEqualToSize(scaledImage.size, size)) {
        scaledImage = [image resizeTo:size];
    }
    
    UIImagePixelSource * pixelSource = [[UIImagePixelSource alloc] initWithImage:scaledImage];
    ANCutColorTable * colorTable = [[ANCutColorTable alloc] initWithTransparentFirst:YES pixelSource:pixelSource];
    ANGifImageFrame *frame = [[ANGifImageFrame alloc] initWithPixelSource:pixelSource colorTable:colorTable delayTime:delay];
    return frame;
}

- (UIImage *)renderFrameAtTime:(FrameTime *)time size:(CGSize)size {
    __block UIImage *image = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIGraphicsBeginImageContextWithOptions(self.cropRect.size, NO, 0);
        [[UIColor whiteColor] setFill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.cropRect.size.width, self.cropRect.size.height)] fill];
        [self _askDelegateToRenderFrame:time];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return [image resizeTo:size]; // TODO: do this more efficiently by drawing directly into the correct-sized image
}

- (NSInteger)repeatCount {
    return 1;
}

@end
