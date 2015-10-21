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
#import "computer-Swift.h"

@interface _FillView : UIView

@property (nonatomic) SKFill *fill;

@end

@implementation _FillView

- (void)setFill:(SKFill *)fill {
    _fill = fill;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [self.fill drawInRect:rect];
}

- (BOOL)isOpaque {
    return NO;
}

@end


@interface ShapeDrawable ()

@property (nonatomic) CAShapeLayer *fillClipShape, *strokeShape;
@property (nonatomic) _FillView *fillView;

@end

@implementation ShapeDrawable

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.path = [aDecoder decodeObjectForKey:@"path"];
    self.fill = [aDecoder decodeObjectForKey:@"fill"];
    self.strokeColor = [aDecoder decodeObjectForKey:@"strokeColor"];
    self.strokeWidth = [aDecoder decodeFloatForKey:@"strokeWidth"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.path forKey:@"path"];
    [aCoder encodeObject:self.fill forKey:@"fill"];
    [aCoder encodeObject:self.strokeColor forKey:@"strokeColor"];
    [aCoder encodeFloat:self.strokeWidth forKey:@"strokeWidth"];
}

- (void)setFill:(SKFill *)fill {
    self.fillView.fill = fill;
    self.fillView.hidden = fill == nil;
}

- (SKFill *)fill {
    return self.fillView.fill;
}

- (void)setup {
    [super setup];
    self.opaque = NO;
    self.fillView = [_FillView new];
    [self addSubview:self.fillView];
    self.fillClipShape = [CAShapeLayer layer];
    self.strokeShape = [CAShapeLayer layer];
    self.strokeShape.fillColor = nil;
    [self.layer addSublayer:self.strokeShape];
    self.fillView.layer.mask = self.fillClipShape;
    self.path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 200, 200)];
    self.fillClipShape.strokeColor = nil;
    
    self.fill = [[SKColorFill alloc] initWithColor:[UIColor blueColor]];
    self.strokeWidth = 0;
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
    self.strokeShape.strokeColor = strokeColor.CGColor;
}

- (void)setStrokeWidth:(CGFloat)strokeWidth {
    _strokeWidth = strokeWidth;
    self.strokeShape.lineWidth = strokeWidth;
    self.strokeShape.hidden = strokeWidth == 0;
}

- (void)setPath:(UIBezierPath *)path {
    [self _setPathWithoutFittingContent:path];
    [self fitContent];
    [self updatedKeyframeProperties];
}

- (void)_setPathWithoutFittingContent:(UIBezierPath *)path {
    CGPathRef cgPath = path.CGPath;
    self.fillClipShape.path = cgPath;
    self.strokeShape.path = cgPath;
}

- (UIBezierPath *)path {
    return self.fillClipShape.path ? [UIBezierPath bezierPathWithCGPath:self.fillClipShape.path] : nil;
}

- (void)fitContent {
    CGRect boundingBox = CGPathGetBoundingBox(self.fillClipShape.path);
    if (!CGRectIsNull(boundingBox)) {
        CGFloat xGrow = boundingBox.size.width - self.bounds.size.width;
        CGFloat yGrow = boundingBox.size.height - self.bounds.size.height;
        self.bounds = CGRectMake(0, 0, boundingBox.size.width, boundingBox.size.height);
        CGPoint subtractFromOrigin = boundingBox.origin;
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-subtractFromOrigin.x, -subtractFromOrigin.y);
        self.fillClipShape.path = self.strokeShape.path = CGPathCreateCopyByTransformingPath(self.fillClipShape.path, &transform);
        self.center = CGPointMake(self.center.x + subtractFromOrigin.x + xGrow/2, self.center.y + subtractFromOrigin.y + yGrow/2);
    }
    self.strokeShape.frame = self.fillView.frame = self.bounds;
    self.fillClipShape.frame = self.fillView.bounds;
}

- (void)primaryEditAction {
    SKFillPicker *picker = [[SKFillPicker alloc] initWithFill:self.fill];
    __weak ShapeDrawable *weakSelf = self;
    picker.callback = ^(id fill) {
        weakSelf.fill = fill;
    };
    [NPSoftModalPresentationController presentViewController:picker];
}

- (void)setInternalSize:(CGSize)size {
    CGPoint oldCenter = self.center;
    CGSize oldSize = self.bounds.size;
    UIBezierPath *path = self.path;
    [path applyTransform:CGAffineTransformMakeScale(size.width / oldSize.width, size.height / oldSize.height)];
    self.path = path;
    self.center = oldCenter;
}

@end
