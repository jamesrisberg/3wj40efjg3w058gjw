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

@class Canvas;
@protocol CanvasDelegate <NSObject>

- (void)canvasDidChangeSelection:(Canvas *)canvas;
- (void)canvasSelectionRectNeedsUpdate:(Canvas *)canvas;
- (void)canvasDidUpdateKeyframesForCurrentTime:(Canvas *)canvas;
- (void)canvas:(Canvas *)canvas shouldShowEditingPanel:(UIView *)panel;
- (void)canvasShowShouldOptions:(Canvas *)canvas withInteractivePresenter:(UIPercentDrivenInteractiveTransition *)presenter touch:(UITouch *)touch;

@end


@interface Canvas : UIView <NSCopying>

- (void)insertDrawable:(Drawable *)drawable;
- (NSArray<__kindof Drawable*>*)drawables;

@property (nonatomic) NSSet *selectedItems;
@property (nonatomic) BOOL multipleSelectionEnabled;
- (void)userGesturedToSelectDrawable:(Drawable *)d;

@property (nonatomic, weak) ShapeStackList *editorShapeStackList;

@property (nonatomic) FrameTime *time;
@property (nonatomic) BOOL useTimeForStaticAnimations;
@property (nonatomic) BOOL overrideDimming;

@property (nonatomic,weak) id<CanvasDelegate> delegate;

- (void)resizeBoundsToFitContent;

- (void)_addDrawableToCanvas:(Drawable *)drawable aboveDrawable:(Drawable *)other;

- (FrameTime *)duration;

- (void)createGroup:(id)sender;

@end
