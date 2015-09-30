//
//  EditorViewController.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Canvas;
@class ShapeStackList;
@class ShapeDrawable;
#import "CMDocument.h"

@interface EditorViewController : UIViewController <CMDocumentDelegate>

@property (nonatomic, readonly) Canvas *canvas;
- (void)showOptions;
@property (nonatomic) BOOL scrollModeActive;
- (void)startFreehandDrawingToShape:(ShapeDrawable *)shape;

+ (EditorViewController *)modalEditorForCanvas:(Canvas *)canvas callback:(void(^)(Canvas *edited))callback;

@property (nonatomic) CMDocument *document;

@end
