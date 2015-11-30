//
//  CMDocument.h
//  computer
//
//  Created by Nate Parrott on 9/6/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CMDocument, CMCanvas;
@protocol CMDocumentDelegate <NSObject>

- (void)document:(CMDocument *)document loadedCanvas:(CMCanvas *)canvas;
- (CMCanvas *)canvasForDocument:(CMDocument *)document;

- (UIImage *)canvasSnapshotForDocument:(CMDocument *)document;

@end

@interface CMDocument : UIDocument

@property (nonatomic,weak) id<CMDocumentDelegate> delegate;

+ (NSURL *)documentsURL;
+ (NSURL *)URLForNewDocument;

+ (void)loadSnapshotForDocumentAtURL:(NSURL *)documentURL callback:(void(^)(UIImage *snapshot))callback;
// callback comes on main thread

- (void)maybeEdited;

- (NSFileWrapper *)fileWrapper;

@end
