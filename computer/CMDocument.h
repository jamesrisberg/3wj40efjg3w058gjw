//
//  CMDocument.h
//  computer
//
//  Created by Nate Parrott on 9/6/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AUTOSAVE_INTERVAL 10.0 // 10 secs

@class CMDocument, CMCanvas;
@protocol CMDocumentDelegate <NSObject>

- (void)document:(CMDocument *)document loadedCanvas:(CMCanvas *)canvas;
- (CMCanvas *)canvasForDocument:(CMDocument *)document;
- (UIImage *)canvasSnapshotForDocument:(CMDocument *)document;

@end

@interface CMDocument : NSObject

+ (CMDocument *)createDocument;
- (instancetype)initWithURL:(NSURL *)url;
@property (nonatomic,readonly) NSURL *url;
@property (nonatomic) BOOL open; // setting open=true causes callbacks to be fired; open=false causes save

- (void)save;

@property (nonatomic,weak) id<CMDocumentDelegate> delegate;

+ (NSURL *)documentsURL;
+ (void)loadSnapshotForDocumentAtURL:(NSURL *)documentURL callback:(void(^)(UIImage *snapshot))callback;
// callback comes on main thread

@property (nonatomic) BOOL hasUnsavedChanges;

@end
