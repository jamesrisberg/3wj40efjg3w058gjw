//
//  CMVideoObjectTrackingData.m
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMVideoObjectTrackingData.h"
#import "CMLayoutBase.h"
#import "Keyframe.h"
@import AVFoundation;
@import CoreImage;
#import "AVAssetTrack+Orientation.h"
#import "computer-Swift.h"

@interface CMVideoObjectTrackingData ()

@property (nonatomic) NSDictionary<NSString*, CMVideoTrackedObject*> *objects;

@end

@implementation CMVideoObjectTrackingData

+ (void)trackObjectsInVideo:(NSURL *)video callback:(void(^)(CMVideoObjectTrackingData *result))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVAsset *asset = [AVAsset assetWithURL:video];
        AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
        CGAffineTransform transform = videoTrack.preferredTransform;
        CGSize size = videoTrack.naturalSize;
        
        CIContext *context = [CIContext contextWithOptions:nil];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:@{CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorTracking: @YES, CIDetectorAspectRatio: @(videoTrack.orientation)}];
        
        NSDictionary *outputSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] };
        AVAssetReaderTrackOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:outputSettings];
        [reader addOutput:trackOutput];
        [reader startReading];
        
        NSMutableDictionary *objectsByTrackingID = [NSMutableDictionary new];
        NSMutableDictionary *objectsByUUID = [NSMutableDictionary new];
        
        CMSampleBufferRef buffer = NULL;
        BOOL continueReading = YES;
        while (continueReading) {
            AVAssetReaderStatus status = [reader status];
            switch (status) {
                case AVAssetReaderStatusUnknown: {
                } break;
                case AVAssetReaderStatusReading: {
                    buffer = [trackOutput copyNextSampleBuffer];
                    NSTimeInterval time = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(buffer));
                    
                    CIImage *image = [CIImage imageWithCVImageBuffer:CMSampleBufferGetImageBuffer(buffer)];
                    for (CIFaceFeature *feature in [detector featuresInImage:image]) {
                        NSNumber *trackingID = @([feature trackingID]);
                        CMVideoTrackedObject *object = objectsByTrackingID[trackingID];
                        if (!object) {
                            object = [CMVideoTrackedObject new];
                            objectsByTrackingID[trackingID] = object;
                            objectsByUUID[object.uuid] = object;
                            object.name = [NSString stringWithFormat:NSLocalizedString(@"Face #%@", @""), @(objectsByTrackingID.count)];
                        }
                        [object appendSample:feature imageSize:size transform:transform time:time];
                    }
                    
                    if (!buffer) {
                        break;
                    }
                } break;
                case AVAssetReaderStatusCompleted: {
                    continueReading = NO;
                    
                    CMVideoObjectTrackingData *result = [CMVideoObjectTrackingData new];
                    result.objects = objectsByUUID;
                    callback(result);
                } break;
                case AVAssetReaderStatusFailed: {
                    [reader cancelReading];
                    continueReading = NO;
                    callback(nil);
                } break;
                case AVAssetReaderStatusCancelled: {
                    continueReading = NO;
                    callback(nil);
                } break;
            }
            if (buffer) {
                CMSampleBufferInvalidate(buffer);
                CFRelease(buffer);
                buffer = NULL;
            }
        }
    });
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.objects = [aDecoder decodeObjectForKey:@"objects"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.objects forKey:@"objects"];
}

@end
