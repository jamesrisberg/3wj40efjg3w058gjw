//
//  VideoExporter.m
//  computer
//
//  Created by Nate Parrott on 10/28/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "VideoExporter.h"
#import "Keyframe.h"
#import "computer-Swift.h"
@import AVFoundation;
#import "HJImagesToVideo.h"
#import "VideoConstants.h"

@interface VideoExporter ()

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) NSString *path;
\
@end

@implementation VideoExporter

- (void)start {
    self.queue = dispatch_queue_create("video queue", 0);
    dispatch_async(self.queue, ^{
        //NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"video.mp4"];
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video.mp4"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        self.path = path;
        NSLog(@"Path: %@", path);
        
        CGSize size = self.cropRect.size;
        size.width *= [UIScreen mainScreen].scale;
        size.height *= [UIScreen mainScreen].scale;
        CGFloat maxDimension = 800;
        CGFloat scale = MIN(1, MIN(maxDimension / size.width, maxDimension / size.height));
        size.width = round(size.width * scale);
        size.height = round(size.height * scale);
        NSInteger fps = VC_FPS;
        
        NSMutableArray *frames = [NSMutableArray new];
        NSInteger i = 0;
        FrameTime *time = [[FrameTime alloc] initWithFrame:i++ atFPS:fps];
        while (time.time <= self.endTime.time) {
            OnDemandImage *frame = [OnDemandImage new];
            frame.userInfo = time;
            frame.fn = ^UIImage*(id userInfo) {
                __block UIImage *image = nil;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    image = [self improperlySizedImageAtTime:userInfo];
                });
                image = [image resizeTo:size];
                return image;
            };
            [frames addObject:frame];
            time = [[FrameTime alloc] initWithFrame:i++ atFPS:fps];
        }
        
        [HJImagesToVideo videoFromImages:frames toPath:self.path withSize:size withFPS:(int)fps animateTransitions:NO withCallbackBlock:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL *videoURL = [NSURL fileURLWithPath:path];
                UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[videoURL] applicationActivities:nil];
                [self.parentViewController presentViewController:activityVC animated:YES completion:nil];
                // TODO: delete the temp file?
                [self.delegate exporterDidFinish:self];
            });
        }];
    });
}

- (UIImage *)improperlySizedImageAtTime:(FrameTime *)time {
    UIGraphicsBeginImageContextWithOptions(self.cropRect.size, NO, 0);
    [[UIColor whiteColor] setFill];
    [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.cropRect.size.width, self.cropRect.size.height)] fill];
    [self _askDelegateToRenderFrame:time];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark Utils

// from http://www.cakesolutions.net/teamblogs/2014/03/08/cmsamplebufferref-from-cgimageref

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image),
                                  CGImageGetHeight(image));
    NSDictionary *options =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithBool:YES],
     kCVPixelBufferCGImageCompatibilityKey,
     [NSNumber numberWithBool:YES],
     kCVPixelBufferCGBitmapContextCompatibilityKey,
     nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status =
    CVPixelBufferCreate(
                        kCFAllocatorDefault, frameSize.width, frameSize.height,
                        kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options,
                        &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
                                                 pxdata, frameSize.width, frameSize.height,
                                                 8, CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGBitmapByteOrder32Little |
                                                 kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (CMSampleBufferRef)sampleBufferFromCGImage:(CGImageRef)image timing:(CMSampleTimingInfo *)timingInfo
{
    CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage:image];
    CMSampleBufferRef newSampleBuffer = NULL;
    
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(
                                                 NULL, pixelBuffer, &videoInfo);
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,
                                       pixelBuffer,
                                       true,
                                       NULL,
                                       NULL,
                                       videoInfo,
                                       timingInfo,
                                       &newSampleBuffer);
    
    return newSampleBuffer;
}

@end
