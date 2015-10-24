//
//  EditorViewController.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Canvas.h"
@class ShapeStackList;
@class ShapeDrawable;
#import "CMDocument.h"

typedef NS_ENUM(NSInteger, EditorMode) {
    EditorModeNormal = 0,
    EditorModeScroll,
    EditorModeTimeline,
    EditorModeDrawing,
    EditorModePanelView
};

@interface EditorViewController : UIViewController <CMDocumentDelegate, CanvasDelegate>

@property (nonatomic, readonly) Canvas *canvas;
- (void)showOptions;
- (void)startFreehandDrawingToShape:(ShapeDrawable *)shape;
@property (nonatomic) EditorMode mode;

+ (EditorViewController *)editor;
+ (EditorViewController *)modalEditorForCanvas:(Canvas *)canvas callback:(void(^)(Canvas *edited))callback;

@property (nonatomic) CMDocument *document;

- (void)presentFromSnapshot:(UIImageView *)snapshot inViewController:(UIViewController *)vc;

- (void)startExport;

@end
