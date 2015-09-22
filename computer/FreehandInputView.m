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

@end

@implementation FreehandInputView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.path = self.shape.path.copy ? : [UIBezierPath bezierPath];
    [self.path moveToPoint:[[touches anyObject] locationInView:self.shape]];
}

/*- (void)touchesEstimatedPropertiesUpdated:(NSSet *)touches {
    
}*/

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.path addLineToPoint:[[touches anyObject] locationInView:self.shape]];
    [self.shape _setPathWithoutFittingContent:self.path];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.shape.path = self.path;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.shape.path = self.path;
}

@end
