//
//  Canvas.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Keyframe.h"
@class Drawable, ShapeStackList;
#import "CMTransaction.h"
#import "CanvasPosition.h"
@class CMCanvas, CMDrawable, CMCameraDrawable;

@class CanvasEditor, _CMCanvasView;

@interface CanvasCoordinateSpace : NSObject <UICoordinateSpace>

@property (nonatomic,weak) _CMCanvasView *canvasView;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGSize screenSpan; // horizontal
- (CGFloat)actualHorizontalScreenSpan;
@property (nonatomic,readonly) CGRect bounds;

@end

@protocol CanvasDelegate <NSObject>

- (void)canvasDidChangeSelection:(CanvasEditor *)canvas;
- (void)canvasDidUpdateKeyframesForCurrentTime:(CanvasEditor *)canvas;
- (void)canvas:(CanvasEditor *)canvas shouldShowEditingPanel:(UIView *)panel;
- (void)canvas:(CanvasEditor *)canvas shouldShowPropertiesViewForDrawables:(NSArray<CMDrawable*>*)drawables;
- (void)canvas:(CanvasEditor *)canvas performDefaultEditActionForDrawables:(NSArray<CMDrawable*>*)drawables;

@end


@interface CanvasEditor : UIView

- (void)insertDrawableAtCurrentTime:(CMDrawable *)drawable;

@property (nonatomic) CMCanvas *canvas;

@property (nonatomic) NSSet<CMDrawable*> *selectedItems;
- (NSArray<CMDrawable*>*)selectedItemsOrderedByZ;
@property (nonatomic) BOOL multipleSelectionEnabled;
- (void)userGesturedToSelectDrawable:(CMDrawable *)d;

@property (nonatomic, weak) ShapeStackList *editorShapeStackList;

@property (nonatomic,weak) id<CanvasDelegate> delegate;

@property (nonatomic) BOOL useTimeForStaticAnimations;
@property (nonatomic) FrameTime *time;
@property (nonatomic) BOOL renderMetaInfo;
@property (nonatomic) BOOL renderDeleteKeyframeButtons;

- (FrameTime *)duration;
- (FrameTime *)loopingDuration; // may return nil

@property (nonatomic) NSInteger repeatCount;
@property (nonatomic) BOOL reboundAnimation;

@property (nonatomic) BOOL preparedForStaticScreenshot;

@property (nonatomic,readonly) CMTransactionStack *transactionStack;

- (UIViewController *)vcForModals;

@property (nonatomic,readonly) _CMCanvasView *canvasView;

- (void)renderNow;

#pragma mark Coordinates

@property (nonatomic,readonly) CanvasPosition *position;
@property (nonatomic,readonly) CanvasCoordinateSpace *canvasCoordinateSpace;
@property (nonatomic) CMCameraDrawable *trackingCamera;
@property (nonatomic) CanvasPosition *defaultPosition; // used when trackingCamera=null

- (CGFloat)canvasZoom; // multiply to convert canvas coords to screen coords

#pragma mark Actions

- (void)deleteDrawable:(CMDrawable *)d;
- (void)duplicateDrawable:(CMDrawable *)d;
- (void)deleteCurrentKeyframeForDrawable:(CMDrawable *)d;

- (void)deleteSelection;
- (void)duplicateSelection;

#pragma mark Misc.

- (NSArray<UIImage*>*)snapshotsOfAllDrawables;

#pragma mark Camera

@end
