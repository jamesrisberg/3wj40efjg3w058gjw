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
#import "ConvenienceCategories.h"

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
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorTracking: @YES}];
        
        NSDictionary *outputSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] };
        AVAssetReaderTrackOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:outputSettings];
        [reader addOutput:trackOutput];
        [reader startReading];
        
        NSMutableDictionary *objectsByTrackingID = [NSMutableDictionary new];
        
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
                    for (CIFaceFeature *feature in [detector featuresInImage:image options:@{CIDetectorImageOrientation: @(videoTrack.orientation)}]) {
                        NSNumber *trackingID = @([feature trackingID]);
                        CMVideoTrackedObject *object = objectsByTrackingID[trackingID];
                        if (!object) {
                            object = [CMVideoTrackedObject new];
                            objectsByTrackingID[trackingID] = object;
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
                    result.objects = [self matchAndNameObjects:objectsByTrackingID.allValues];
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

+ (NSDictionary<NSString*,CMVideoTrackedObject*>*)matchAndNameObjects:(NSArray<CMVideoTrackedObject*> *)objects {
    NSArray *itemsByTime = [objects sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSTimeInterval t1 = [(CMVideoTrackedObject *)obj1 minFrameTime];
        NSTimeInterval t2 = [(CMVideoTrackedObject *)obj2 minFrameTime];
        if (t1 < t2) {
            return NSOrderedAscending;
        } else if (t1 == t2) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
    NSMutableArray *finalObjects = [NSMutableArray new];
    for (CMVideoTrackedObject *obj in itemsByTime) {
        BOOL matched = NO;
        /*for (CMVideoTrackedObject *other in finalObjects) {
            if (![obj overlapsWithOtherObjectTemporally:other]) {
                [other appendFramesFromObject:obj];
                matched = YES;
                break;
            }
        }*/
        if (!matched) {
            [finalObjects addObject:obj];
        }
    }
    
    // sort by frame count:
    [finalObjects sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSInteger f1 = [obj1 frameCount];
        NSInteger f2 = [obj2 frameCount];
        if (f1 < f2) {
            return NSOrderedDescending;
        } else if (f1 == f2) {
            return NSOrderedSame;
        } else {
            return NSOrderedAscending;
        }
    }];
    NSInteger i = 1;
    for (CMVideoTrackedObject *obj in objects) {
        obj.name = [NSString stringWithFormat:NSLocalizedString(@"Face #%@", @""), @(i++)];
    }
    
    return [finalObjects mapToDict:^id(__autoreleasing id *key) {
        CMVideoTrackedObject *obj = *key;
        *key = obj.uuid;
        return obj;
    }];;
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
