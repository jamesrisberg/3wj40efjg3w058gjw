//
//  CMDocument.m
//  computer
//
//  Created by Nate Parrott on 9/6/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDocument.h"
#import "Canvas.h"

@interface NSFileWrapper (CMAdditions)

@end

@implementation NSFileWrapper (CMAdditions)

- (NSFileWrapper *)setData:(NSData *)data forChildWithName:(NSString *)name {
    NSFileWrapper *existing = self.fileWrappers[name];
    if (existing) [self removeFileWrapper:existing];
    
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
    wrapper.preferredFilename = name;
    [self addFileWrapper:wrapper];
    
    return wrapper;
}

@end


@interface CMDocument () {
    BOOL _hasUnsavedChanges;
}

@property (nonatomic) NSFileWrapper *fileWrapper;

@end

@implementation CMDocument

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    self.fileWrapper = contents;
    NSFileWrapper *canvasWrapper = [self.fileWrapper fileWrappers][@"Canvas"];
    Canvas *canvas = [NSKeyedUnarchiver unarchiveObjectWithData:canvasWrapper.regularFileContents];
    [self.delegate document:self loadedCanvas:canvas];
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    if (!self.fileWrapper) {
        self.fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
    }
    
    NSData *canvasData = [NSKeyedArchiver archivedDataWithRootObject:[self.delegate canvasForDocument:self]];
    [self.fileWrapper setData:canvasData forChildWithName:@"Canvas"];
    
    UIImage *snapshot = [self.delegate canvasSnapshotForDocument:self];
    if (snapshot) {
        [self.fileWrapper setData:UIImagePNGRepresentation(snapshot) forChildWithName:@"Snapshot.png"];
    }
    
    return self.fileWrapper;
}

- (void)saveToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation completionHandler:(void (^)(BOOL))completionHandler {
    _hasUnsavedChanges = NO;
    [super saveToURL:url forSaveOperation:saveOperation completionHandler:completionHandler];
}

#pragma mark Save tracking
- (void)maybeEdited {
    _hasUnsavedChanges = YES;
}

- (BOOL)hasUnsavedChanges {
    return _hasUnsavedChanges;
}

#pragma mark Paths

+ (NSURL *)documentsURL {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [NSURL fileURLWithPath:path];
}

+ (NSURL *)URLForNewDocument {
    NSString *filename = [[[NSUUID UUID] UUIDString] stringByAppendingPathExtension:@"computerdoc"];
    return [[self documentsURL] URLByAppendingPathComponent:filename];
}

#pragma mark Snapshot loading

+ (void)loadSnapshotForDocumentAtURL:(NSURL *)documentURL callback:(void(^)(UIImage *snapshot))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *snapshotURL = [documentURL URLByAppendingPathComponent:@"Snapshot.png"];
        UIImage *image = [UIImage imageWithContentsOfFile:snapshotURL.path];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(image);
        });
    });
}

@end
