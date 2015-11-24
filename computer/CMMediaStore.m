//
//  CMMediaStore.m
//  computer
//
//  Created by Nate Parrott on 11/23/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMMediaStore.h"
@import AVFoundation;

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

- (CMMediaID *)storeMediaAtURL:(NSURL *)url {
    NSString *name = [[NSUUID UUID] UUIDString];
    if (url.pathExtension) name = [name stringByAppendingPathExtension:url.pathExtension];
    
    NSURL *destURL = [NSURL fileURLWithPath:[self.path stringByAppendingPathComponent:name]];
    [[NSFileManager defaultManager] copyItemAtURL:url toURL:destURL error:nil];
    CMMediaID *ID = [CMMediaID new];
    ID.name = name;
    return ID;
}

- (void)resizeAndStoreMediaAtURL:(NSURL *)url callback:(void(^)(CMMediaID *mediaID))callback {
    callback([self storeMediaAtURL:url]); // TODO? or not
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
    return [[self mediaStore] storeMediaAtURL:self.url];
}

- (NSURL *)url {
    NSString *path = [[self mediaStore].path stringByAppendingPathComponent:self.name];
    return [NSURL fileURLWithPath:path];
}

@end
