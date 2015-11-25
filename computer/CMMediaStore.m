//
//  CMMediaStore.m
//  computer
//
//  Created by Nate Parrott on 11/23/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMMediaStore.h"
@import AVFoundation;
@import Photos;

@interface CMMediaID ()

@property (nonatomic) NSString *name;

@end

@interface CMMediaStore ()

@property (nonatomic) NSString *path;

@end

@implementation CMMediaStore

+ (CMMediaStore *)shared {
    static CMMediaStore *shared = nil;
    shared = [CMMediaStore new];
    shared.path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"CMMediaStore"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:shared.path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:shared.path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return shared;
}

- (void)storeMediaAtURL:(NSURL *)url callback:(void(^)(CMMediaID *mediaID))callback {
    NSString *name = [[NSUUID UUID] UUIDString];
    if (url.pathExtension) name = [name stringByAppendingPathExtension:url.pathExtension];
    NSURL *destURL = [NSURL fileURLWithPath:[self.path stringByAppendingPathComponent:name]];
    
    if ([url.scheme isEqualToString:@"assets-library"]) {
        PHFetchResult<__kindof PHAsset*> *results = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
        [results enumerateObjectsUsingBlock:^(__kindof PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[PHImageManager defaultManager] requestExportSessionForVideo:obj options:0 exportPreset:AVAssetExportPreset960x540 resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
                // TODO: show export progress
                exportSession.outputURL = destURL;
                exportSession.outputFileType = AVFileTypeQuickTimeMovie;
                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CMMediaID *ID = [CMMediaID new];
                        ID.name = name;
                        callback(ID);
                    });
                }];
            }];
        }];
    } else if (url.isFileURL) {
        [[NSFileManager defaultManager] copyItemAtURL:url toURL:destURL error:nil];
        CMMediaID *ID = [CMMediaID new];
        ID.name = name;
        callback(ID);
    }
}

@end


@implementation CMMediaID

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    self.name = [aDecoder decodeObjectForKey:@"name"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
}

- (void)dispose {
    [[NSFileManager defaultManager] removeItemAtURL:self.url error:nil];
    self.name = nil;
}

- (CMMediaStore *)mediaStore {
    return [CMMediaStore shared];
}

- (CMMediaID *)newReference {
    __block CMMediaID *newId = nil;
    [[self mediaStore] storeMediaAtURL:self.url callback:^(CMMediaID *mediaID) {
        newId = mediaID;
    }];
    return newId; // TODO: this is shitty
}

- (NSURL *)url {
    NSString *path = [[self mediaStore].path stringByAppendingPathComponent:self.name];
    return [NSURL fileURLWithPath:path];
}

@end
