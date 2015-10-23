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

@end


@interface Canvas : UIView <NSCopying>

- (void)insertDrawable:(Drawable *)drawable;
- (NSArray<__kindof Drawable*>*)drawables;

@property (nonatomic) Drawable *selection;

@property (nonatomic, weak) ShapeStackList *editorShapeStackList;

@property (nonatomic) FrameTime *time;

@property (nonatomic,weak) id<CanvasDelegate> delegate;

- (void)resizeBoundsToFitContent;

- (void)_addDrawableToCanvas:(Drawable *)drawable aboveDrawable:(Drawable *)other;

@end
