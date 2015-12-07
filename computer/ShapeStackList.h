//
//  ShapeStackList.h
//  computer
//
//  Created by Nate Parrott on 9/4/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CMDrawable, _CMCanvasView, CMCanvas;

@interface ShapeStackList : UIView

@property (nonatomic,weak) _CMCanvasView *canvasView;
@property (nonatomic,weak) CMCanvas *canvas;

// set this _after_ setting canvasView and canvas
// will automatically be sorted in reverse-z order
@property (nonatomic) NSArray<CMDrawable*> *drawables;

@property (nonatomic,copy) void (^onDrawableSelected)(CMDrawable *drawable);
- (void)show;
- (void)hide;

@end
