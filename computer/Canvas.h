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
#import "CMCanvas.h"

@class Canvas;
@protocol CanvasDelegate <NSObject>

- (void)canvasDidChangeSelection:(Canvas *)canvas;
- (void)canvasSelectionRectNeedsUpdate:(Canvas *)canvas;
- (void)canvasDidUpdateKeyframesForCurrentTime:(Canvas *)canvas;
- (void)canvas:(Canvas *)canvas shouldShowEditingPanel:(UIView *)panel;
- (void)canvasShowShouldOptions:(Canvas *)canvas withInteractivePresenter:(UIPercentDrivenInteractiveTransition *)presenter touchPos:(CGPoint)pos;

@end


@interface Canvas : UIView <NSCopying, TimeAware>

// - (void)insertDrawable:(Drawable *)drawable;
// - (NSArray<__kindof Drawable*>*)drawables;

- (void)insertDrawableAtCurrentTime:(CMDrawable *)drawable;

@property (nonatomic) CMCanvas *canvas;

@property (nonatomic) NSSet *selectedItems;
@property (nonatomic) BOOL multipleSelectionEnabled;
- (void)userGesturedToSelectDrawable:(Drawable *)d;

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

@end
