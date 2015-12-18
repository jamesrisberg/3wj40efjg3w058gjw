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
@class CMCanvas, CMDrawable;

@class CanvasEditor, _CMCanvasView;

@interface CanvasCoordinateSpace : NSObject <UICoordinateSpace>

@property (nonatomic,weak) _CMCanvasView *canvasView;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat screenSpan; // horizontal
@property (nonatomic,readonly) CGRect bounds;

@end

@protocol CanvasDelegate <NSObject>

- (void)canvasDidChangeSelection:(CanvasEditor *)canvas;
- (void)canvasDidUpdateKeyframesForCurrentTime:(CanvasEditor *)canvas;
- (void)canvas:(CanvasEditor *)canvas shouldShowEditingPanel:(UIView *)panel;
- (void)canvasShowShouldOptions:(CanvasEditor *)canvas withInteractivePresenter:(UIPercentDrivenInteractiveTransition *)presenter touchPos:(CGPoint)pos;
- (void)canvas:(CanvasEditor *)canvas shouldShowPropertiesViewForDrawables:(NSArray<CMDrawable*>*)drawables;

@end


@interface CanvasEditor : UIView <TimeAware>

// - (void)insertDrawable:(Drawable *)drawable;
// - (NSArray<__kindof Drawable*>*)drawables;

- (void)insertDrawableAtCurrentTime:(CMDrawable *)drawable;

@property (nonatomic) CMCanvas *canvas;

@property (nonatomic) NSSet<CMDrawable*> *selectedItems;
@property (nonatomic) BOOL multipleSelectionEnabled;
- (void)userGesturedToSelectDrawable:(CMDrawable *)d;

@property (nonatomic, weak) ShapeStackList *editorShapeStackList;

@property (nonatomic,weak) id<CanvasDelegate> delegate;

@property (nonatomic) BOOL useTimeForStaticAnimations;
@property (nonatomic) FrameTime *time;
@property (nonatomic) BOOL suppressTimingVisualizations;

- (void)_addDrawableToCanvas:(Drawable *)drawable aboveDrawable:(Drawable *)other;

- (FrameTime *)duration;
- (FrameTime *)loopingDuration; // may return nil

@property (nonatomic) NSInteger repeatCount;
@property (nonatomic) BOOL reboundAnimation;

@property (nonatomic) BOOL preparedForStaticScreenshot;

@property (nonatomic,readonly) CMTransactionStack *transactionStack;

- (UIViewController *)vcForModals;

@property (nonatomic,readonly) _CMCanvasView *canvasView;

#pragma mark Coordinates

@property (nonatomic) CGPoint centerOfVisibleArea;
@property (nonatomic) CGFloat screenSpan; // if 100, then a 100pt-wide object will fill the canvas view
@property (nonatomic,readonly) CanvasCoordinateSpace *canvasCoordinateSpace;

- (CGFloat)canvasZoom; // multiply to convert canvas coords to screen coords

#pragma mark Actions

- (void)deleteDrawable:(CMDrawable *)d;
- (void)duplicateDrawable:(CMDrawable *)d;
- (void)deleteCurrentKeyframeForDrawable:(CMDrawable *)d;

- (void)deleteSelection;
- (void)duplicateSelection;

#pragma mark Misc.

- (NSArray<UIImage*>*)snapshotsOfAllDrawables;

@end
