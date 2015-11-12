//
//  FreehandInputView.m
//  computer
//
//  Created by Nate Parrott on 9/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FreehandInputView.h"
#import "ShapeDrawable.h"

@interface FreehandInputView ()

@property (nonatomic) UIBezierPath *path;
@property (nonatomic) NSMutableArray *previewStrokeStack;

@end

@implementation FreehandInputView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.path = self.shape.path.copy ? : [UIBezierPath bezierPath];
    [self.path moveToPoint:[[touches anyObject] locationInView:self.shape]];
}

/*- (void)touchesEstimatedPropertiesUpdated:(NSSet *)touches {
    
}*/

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    NSMutableArray *points = [NSMutableArray new];
    [points addObjectsFromArray:[event coalescedTouchesForTouch:touch]];
    [points addObject:touch];
    for (UITouch *touch in points) {
        [self.path addLineToPoint:[touch locationInView:self.shape]];
    }
    [self.shape _setPathWithoutFittingContent:self.path];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.shape.path = self.path;
    
    if (!self.previewStrokeStack) {
        self.previewStrokeStack = [NSMutableArray new];
        [self.previewStrokeStack addObject:[UIBezierPath bezierPath]];
    }
    [self.previewStrokeStack addObject:self.shape.path];
    while (self.previewStrokeStack.count > 10) {
        [self.previewStrokeStack removeObjectAtIndex:0];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.shape.path = self.path;
}

- (void)undoLastStroke {
    if (self.previewStrokeStack.count >= 2) {
        [self.previewStrokeStack removeLastObject];
        self.shape.path = self.previewStrokeStack.lastObject;
    }
}

@end
