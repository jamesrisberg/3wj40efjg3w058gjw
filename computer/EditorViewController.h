//
//  EditorViewController.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CanvasEditor.h"
@class ShapeStackList;
@class ShapeDrawable;
#import "CMDocument.h"

typedef NS_ENUM(NSInteger, EditorMode) {
    EditorModeNormal = 0,
    EditorModeScroll,
    EditorModeTimeline,
    EditorModeDrawing,
    EditorModePanelView,
    EditorModeExportCropping,
    EditorModeExportRunning,
    EditorModeSelection,
    EditorModeShowingPropertiesView,
    EditorModeCreatingGroup
};

@interface EditorViewController : UIViewController <CMDocumentDelegate, CanvasDelegate>

@property (nonatomic, readonly) CanvasEditor *canvas;
- (void)startFreehandDrawing;
@property (nonatomic) EditorMode mode;
- (void)enterSelectionMode;

+ (EditorViewController *)editor;
+ (EditorViewController *)modalEditorForCanvas:(CMCanvas *)canvas callback:(void(^)(CMCanvas *edited))callback;

@property (nonatomic) CMDocument *document;

- (void)presentFromSnapshot:(UIImageView *)snapshot inViewController:(UIViewController *)vc;

- (void)beginExportFlow;

- (void)beginCreatingGroup;

@property (nonatomic) NSString *editPrompt;

- (void)showPropertyEditors;
- (void)updatePropertyEditors;

@end
