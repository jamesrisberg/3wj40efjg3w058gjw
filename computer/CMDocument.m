//
//  CMDocument.m
//  computer
//
//  Created by Nate Parrott on 9/6/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDocument.h"
#import "CMCanvas.h"
#import "CMWindow.h"

@interface CMDocument () {
    NSTimer *_autoSaveTimer;
    CFAbsoluteTime _timeOfEarliestUnsavedChange;
}

@property (nonatomic) NSURL *url;

@end

@implementation CMDocument

#pragma mark Loading

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    self.url = url;
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        [[NSFileManager defaultManager] createDirectoryAtURL:self.url withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(touchesEnded) name:CMWindowGlobalTouchesEndedNotification object:nil];
    return self;
}

- (void)setOpen:(BOOL)open {
    if (open != _open) {
        if (open) {
            // initial opening:
            _open = YES;
            [self load];
        } else {
            // closing:
            [self save];
            _open = NO;
        }
    }
}

- (void)load {
    CMCanvas *canvas;
    NSURL *canvasURL = [self.url URLByAppendingPathComponent:@"Canvas"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:canvasURL.path]) {
        canvas = [NSKeyedUnarchiver unarchiveObjectWithFile:canvasURL.path];
    } else {
        canvas = [CMCanvas new];
    }
    [self.delegate document:self loadedCanvas:canvas];
}

- (void)save {
    // TODO: do everything atomically (?)
    NSData *canvasData = [NSKeyedArchiver archivedDataWithRootObject:[self.delegate canvasForDocument:self]];
    [canvasData writeToURL:[self.url URLByAppendingPathComponent:@"Canvas" isDirectory:NO] atomically:YES];
    
    UIImage *snapshot = [self.delegate canvasSnapshotForDocument:self];
    if (snapshot) {
        [UIImagePNGRepresentation(snapshot) writeToURL:[self.url URLByAppendingPathComponent:@"Snapshot.png"] atomically:YES];
    }
    self.hasUnsavedChanges = NO;
}

- (void)setHasUnsavedChanges:(BOOL)hasUnsavedChanges {
    _hasUnsavedChanges = hasUnsavedChanges;
    if (hasUnsavedChanges) {
        if (!_timeOfEarliestUnsavedChange) {
            _timeOfEarliestUnsavedChange = CFAbsoluteTimeGetCurrent();
        }
        if (!_autoSaveTimer) {
            _autoSaveTimer = [NSTimer scheduledTimerWithTimeInterval:AUTOSAVE_INTERVAL target:self selector:@selector(autosaveIfNecessary) userInfo:nil repeats:YES];
        }
    } else {
        [_autoSaveTimer invalidate];
        _autoSaveTimer = nil;
        _timeOfEarliestUnsavedChange = 0;
    }
}

- (void)autosaveIfNecessary {
    CMWindow *window = (CMWindow *)[UIApplication sharedApplication].windows.firstObject;
    if (window.touchesAreDown) return;
    
    if (CFAbsoluteTimeGetCurrent() - _timeOfEarliestUnsavedChange >= AUTOSAVE_INTERVAL) {
        [self save];
    }
}

- (void)touchesEnded {
    [self autosaveIfNecessary];
}

/*- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    self.fileWrapper = contents;
    NSFileWrapper *canvasWrapper = [self.fileWrapper fileWrappers][@"Canvas"];
    CanvasEditor *canvas = [NSKeyedUnarchiver unarchiveObjectWithData:canvasWrapper.regularFileContents];
    [self.delegate document:self loadedCanvas:canvas];
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
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
}*/


#pragma mark Creation

+ (CMDocument *)createDocument {
    CMDocument *doc = [[CMDocument alloc] initWithURL:[[self class] URLForNewDocument]];
    return doc;
}

#pragma mark URLs

+ (NSURL *)documentsURL {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [NSURL fileURLWithPath:path];
}

+ (NSURL *)URLForNewDocument {
    NSString *filename = [[[NSUUID UUID] UUIDString] stringByAppendingPathExtension:@"computerdoc"];
    return [[self documentsURL] URLByAppendingPathComponent:filename isDirectory:YES];
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
