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

@end


@interface Canvas : UIView <NSCopying>

- (void)insertDrawable:(Drawable *)drawable;
@property (nonatomic) Drawable *selection;
@property (nonatomic,copy) void (^selectionRectNeedUpdate)();

@property (nonatomic, weak) ShapeStackList *editorShapeStackList;

@property (nonatomic) FrameTime *time;

@end
