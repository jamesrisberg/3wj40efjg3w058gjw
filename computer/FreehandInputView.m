//
//  FreehandInputView.m
//  computer
//
//  Created by Nate Parrott on 9/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FreehandInputView.h"
#import "CMCanvas.h"
#import "CMTransaction.h"
#import "CMShapeDrawable.h"
#import "CanvasEditor.h"
#import "CGPointExtras.h"
#import "computer-Swift.h"

@interface FreehandInputView () {
    CMTransactionStack *_stack;
    CMTransaction *_current;
}

@end

@implementation FreehandInputView

- (instancetype)init {
    self = [super init];
    self.strokeWidth = 2;
    self.strokeColor = [UIColor blackColor];
    _stack = [CMTransactionStack new];
    self.path = [UIBezierPath bezierPath];
    [self shapeLayer].fillColor = nil;
    return self;
}

#pragma mark Shape Layer

+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (CAShapeLayer *)shapeLayer {
    return (id)self.layer;
}

- (void)setPath:(UIBezierPath *)path {
    _path = path;
    [self shapeLayer].path = path.CGPath;
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
    [self shapeLayer].strokeColor = strokeColor.CGColor;
}

- (void)setStrokeWidth:(CGFloat)strokeWidth {
    _strokeWidth = strokeWidth;
    [self shapeLayer].lineWidth = strokeWidth;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint p = [touches.anyObject locationInView:self];
    __weak FreehandInputView *weakSelf = self;
    UIBezierPath *oldPath = self.path;
    UIBezierPath *newPath = oldPath.copy;
    [newPath moveToPoint:p];
    _current = [[CMTransaction alloc] initImplicitlyFinalizaledWhenTouchesEndWithTarget:self action:^(id target) {
        weakSelf.path = newPath;
    } undo:^(id target) {
        weakSelf.path = oldPath;
    }];
    [_stack doTransaction:_current];
}

/*- (void)touchesEstimatedPropertiesUpdated:(NSSet *)touches {
    
}*/

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint p = [touches.anyObject locationInView:self];
    UIBezierPath *path = self.path.copy;
    [path addLineToPoint:p];
    __weak FreehandInputView *weakSelf = self;
    _current.action = ^(id target) {
        weakSelf.path = path;
    };
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

- (void)undoLastStroke {
    [_stack undo];
}

- (void)insertWithCanvasEditor:(CanvasEditor *)c {
    CGRect bounds = self.path.bounds;
    CMShapeDrawable *shape = [CMShapeDrawable new];
    shape.strokeWidth = self.strokeWidth / c.canvasZoom;
    shape.strokePattern = [Pattern solidColor:self.strokeColor];
    shape.path = self.path;
    shape.aspectRatio = bounds.size.height ? bounds.size.width / bounds.size.height : 1;
    shape.boundsDiagonal = CGRectDiagonal(bounds) / c.canvasZoom;
    CMShapeDrawableKeyframe *keyframe = [shape.keyframeStore createKeyframeAtTimeIfNeeded:c.time];
    keyframe.center = [c.canvasCoordinateSpace convertPoint:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds)) fromCoordinateSpace:self];
    [shape.keyframeStore storeKeyframe:keyframe];
    [c.canvas.contents addObject:shape];
}

@end
