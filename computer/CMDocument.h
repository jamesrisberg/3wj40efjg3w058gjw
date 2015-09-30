//
//  CMDocument.h
//  computer
//
//  Created by Nate Parrott on 9/6/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CMDocument, Canvas;
@protocol CMDocumentDelegate <NSObject>

- (void)document:(CMDocument *)document loadedCanvas:(Canvas *)canvas;
- (Canvas *)canvasForDocument:(CMDocument *)document;

- (UIImage *)canvasSnapshotForDocument:(CMDocument *)document;

@end

@interface CMDocument : UIDocument

@property (nonatomic,weak) id<CMDocumentDelegate> delegate;

+ (NSURL *)documentsURL;
+ (NSURL *)URLForNewDocument;

@end
