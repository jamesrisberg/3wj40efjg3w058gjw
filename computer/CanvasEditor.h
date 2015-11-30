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

@class CanvasEditor;
@protocol CanvasDelegate <NSObject>

- (void)canvasDidChangeSelection:(CanvasEditor *)canvas;
- (void)canvasDidUpdateKeyframesForCurrentTime:(CanvasEditor *)canvas;
- (void)canvas:(CanvasEditor *)canvas shouldShowEditingPanel:(UIView *)panel;
- (void)canvasShowShouldOptions:(CanvasEditor *)canvas withInteractivePresenter:(UIPercentDrivenInteractiveTransition *)presenter touchPos:(CGPoint)pos;

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

- (void)resizeBoundsToFitContent;

- (void)_addDrawableToCanvas:(Drawable *)drawable aboveDrawable:(Drawable *)other;

- (FrameTime *)duration;
- (FrameTime *)loopingDuration; // may return nil

- (void)createGroup:(id)sender;

@property (nonatomic) NSInteger repeatCount;
@property (nonatomic) BOOL reboundAnimation;

@property (nonatomic) BOOL preparedForStaticScreenshot;

@property (nonatomic,readonly) CMTransactionStack *transactionStack;

- (UIViewController *)vcForModals;

#pragma mark Actions

- (void)deleteDrawable:(CMDrawable *)d;
- (void)duplicateDrawable:(CMDrawable *)d;
- (void)deleteCurrentKeyframeForDrawable:(CMDrawable *)d;

@end
