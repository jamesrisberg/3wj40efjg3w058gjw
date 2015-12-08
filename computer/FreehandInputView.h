//
//  FreehandInputView.h
//  computer
//
//  Created by Nate Parrott on 9/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ShapeDrawable, CanvasEditor;

@interface FreehandInputView : UIView

@property (nonatomic) UIBezierPath *path;
@property (nonatomic) UIColor *strokeColor;
@property (nonatomic) CGFloat strokeWidth;

- (void)undoLastStroke;

- (void)insertWithCanvasEditor:(CanvasEditor *)c;

@end
