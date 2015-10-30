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

@interface VideoExporter ()

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) NSString *path;

@end

@implementation VideoExporter

- (void)start {
    self.queue = dispatch_queue_create("video queue", 0);
    dispatch_async(self.queue, ^{
        [self sendProgress:0];
        
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"video.mov"];
        self.path = path;
        
        CGSize size = self.canvasSize;
        CGFloat maxDimension = 800;
        CGFloat scale = MIN(1, MIN(maxDimension / size.width, maxDimension / size.height));
        size.width = round(size.width * scale);
        size.height = round(size.height * scale);
        
        NSError *error = nil;
        AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                      [NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie
                                                                  error:&error];
        NSParameterAssert(videoWriter);
        
        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       AVVideoCodecH264, AVVideoCodecKey,
                                       [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                       [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                       nil];
        AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoSettings];
        NSParameterAssert(writerInput);
        NSParameterAssert([videoWriter canAddInput:writerInput]);
        [videoWriter addInput:writerInput];
        
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
        
        NSInteger fps = 24;
        
        CMSampleTimingInfo timingInfo;
        timingInfo.decodeTimeStamp = kCMTimeInvalid;
        timingInfo.duration = CMTimeMake(1, (int)fps);
        timingInfo.presentationTimeStamp = kCMTimeZero;
        
        NSTimeInterval t = 0;
        while (t < self.endTime.time) {
            [self encodeFrameWithTimingInfo:&timingInfo time:t writer:videoWriter input:writerInput size:size];
            t += 1.0 / fps;
        }
        // [self encodeFrameAtTime:self.endTime.time writer:videoWriter input:writerInput size:size];
        [writerInput markAsFinished];
        [videoWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate exporterDidFinish:self];
            });
        }];
    });
    
}

- (void)encodeFrameWithTimingInfo:(CMSampleTimingInfo *)timingInfo time:(NSTimeInterval)time writer:(AVAssetWriter *)writer input:(AVAssetWriterInput *)input size:(CGSize)size {
    __block UIImage *image = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        image = [self improperlySizedImageAtTime:[[FrameTime alloc] initWithFrame:time * 1000 atFPS:1000]];
    });
    image = [image resizeTo:size];
    if (![input appendSampleBuffer:[[self class] sampleBufferFromCGImage:image.CGImage timing:timingInfo]]) {
        NSLog(@"Failed to append sample buffer; error: %@", writer.error);
    }
}

- (void)sendProgress:(double)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate exporter:self updateProgress:progress];
    });
}

- (UIImage *)improperlySizedImageAtTime:(FrameTime *)time {
    UIGraphicsBeginImageContextWithOptions(self.cropRect.size, NO, 0);
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
