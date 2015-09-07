//
//  ShapeDrawable.m
//  computer
//
//  Created by Nate Parrott on 9/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ShapeDrawable.h"
#import "SKFill.h"
#import "SKColorFill.h"
#import "SKFillPicker.h"
#import "UIViewController+SoftModal.h"

@interface ShapeDrawable ()

@property (nonatomic) CAShapeLayer *shapeLayer;

@end

@implementation ShapeDrawable

- (void)drawRect:(CGRect)rect {
    [self.fill drawInRect:rect];
}

- (void)setFill:(SKFill *)fill {
    _fill = fill;
    [self setNeedsDisplay];
}

- (void)setup {
    [super setup];
    self.opaque = NO;
    self.shapeLayer = [CAShapeLayer layer];
    self.layer.mask = self.shapeLayer;
    self.path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 200, 200)];
    self.shapeLayer.strokeColor = nil;
    self.fill = [[SKColorFill alloc] initWithColor:[UIColor blueColor]];
}

- (void)setPath:(UIBezierPath *)path {
    self.shapeLayer.path = path.CGPath;
    [self fitContent];
}

- (UIBezierPath *)path {
    return [UIBezierPath bezierPathWithCGPath:self.shapeLayer.path];
}

- (void)fitContent {
    CGRect boundingBox = CGPathGetBoundingBox(self.shapeLayer.path);
    self.bounds = CGRectMake(0, 0, boundingBox.size.width, boundingBox.size.height);
    CGPoint subtractFromOrigin = boundingBox.origin;
    CGAffineTransform transform = CGAffineTransformMakeTranslation(-subtractFromOrigin.x, -subtractFromOrigin.y);
    self.shapeLayer.path = CGPathCreateCopyByTransformingPath(self.shapeLayer.path, &transform);
    self.center = CGPointMake(-subtractFromOrigin.x, -subtractFromOrigin.y);
    self.shapeLayer.frame = self.bounds;
}

- (void)primaryEditAction {
    SKFillPicker *picker = [[SKFillPicker alloc] initWithFill:self.fill];
    __weak ShapeDrawable *weakSelf = self;
    picker.callback = ^(id fill) {
        weakSelf.fill = fill;
    };
    [picker presentSoftModalInViewController:self.vcForPresentingModals];
}

@end
