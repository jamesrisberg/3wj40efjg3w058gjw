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
#import "StrokePickerViewController.h"

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

@property (nonatomic) _FillView *fillView;
@property (nonatomic) CAGradientLayer *gradientLayer;
@property (nonatomic) CAShapeLayer *maskShape;

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

- (void)setup {
    [super setup];
    self.clipsToBounds = NO;
    self.path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 200, 200)];
    self.fill = [[SKColorFill alloc] initWithColor:[UIColor blueColor]];
    self.strokeWidth = 0;
}

- (void)setPath:(UIBezierPath *)path {
    [self _setPathWithoutFittingContent:path];
    [self fitContent];
}

- (void)_setPathWithoutFittingContent:(UIBezierPath *)path {
    CAShapeLayer *shape = (id)self.layer;
    shape.path = path.CGPath;
    self.maskShape.path = shape.path;
}

- (UIBezierPath *)path {
    CAShapeLayer *shape = (id)self.layer;
    return shape.path ? [UIBezierPath bezierPathWithCGPath:shape.path] : nil;
}

- (void)fitContent {
    UIBezierPath *path = self.path;
    CGRect boundingBox = [path bounds];
    if (!CGRectIsNull(boundingBox)) {
        CGFloat xGrow = boundingBox.size.width - self.bounds.size.width;
        CGFloat yGrow = boundingBox.size.height - self.bounds.size.height;
        self.bounds = CGRectMake(0, 0, boundingBox.size.width, boundingBox.size.height);
        CGPoint subtractFromOrigin = boundingBox.origin;
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-subtractFromOrigin.x, -subtractFromOrigin.y);
        [path applyTransform:transform];
        self.center = CGPointMake(self.center.x + subtractFromOrigin.x + xGrow/2, self.center.y + subtractFromOrigin.y + yGrow/2);
    }
    [self updatedKeyframeProperties];
    [self _setPathWithoutFittingContent:path];
}

- (void)setPathPreservingSize:(UIBezierPath *)path {
    CGRect boundingRect = path.bounds;
    CGFloat scale = (self.bounds.size.width / boundingRect.size.width + self.bounds.size.height / boundingRect.size.height)/2;
    [path applyTransform:CGAffineTransformMakeScale(scale, scale)];
    CGPoint origin = path.bounds.origin;
    [path applyTransform:CGAffineTransformMakeTranslation(-origin.x, -origin.y)];
    self.path = path;
}

- (void)primaryEditAction {
    SKFillPicker *picker = [[SKFillPicker alloc] initWithFill:self.fill];
    __weak ShapeDrawable *weakSelf = self;
    picker.callback = ^(id fill) {
        weakSelf.fill = fill;
    };
    [NPSoftModalPresentationController presentViewController:picker];
}

- (void)editStroke {
    StrokePickerViewController *picker = [StrokePickerViewController new];
    picker.color = self.strokeColor;
    picker.width = self.strokeWidth;
    __weak ShapeDrawable *weakSelf = self;
    picker.onChange = ^(CGFloat width, UIColor *color) {
        weakSelf.strokeColor = color;
        weakSelf.strokeWidth = width;
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

- (NSArray <__kindof QuickCollectionItem*> *)optionsItems {
    __weak ShapeDrawable *weakSelf = self;
    
    QuickCollectionItem *editFill = [QuickCollectionItem new];
    editFill.label = NSLocalizedString(@"Fill…", @"");
    editFill.action = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf primaryEditAction];
        });
    };
    
    QuickCollectionItem *editStroke = [QuickCollectionItem new];
    editStroke.label = NSLocalizedString(@"Stroke…", @"");
    editStroke.action = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf editStroke];
        });
    };
    
    return [[super optionsItems] arrayByAddingObjectsFromArray:@[editFill, editStroke]];
}

#pragma mark Fills
+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (void)setFill:(SKFill *)fill {
    _fill = fill;
    CAShapeLayer *shape = (id)self.layer;
    if ([self.fill solidColorOrNil]) {
        [_fillView removeFromSuperview];
        _fillView = nil;
        [self.gradientLayer removeFromSuperlayer];
        self.gradientLayer = nil;
        [_maskShape removeFromSuperlayer];
        _maskShape = nil;
        
        shape.fillColor = [self.fill solidColorOrNil].CGColor;
    } else {
        shape.fillColor = nil;
        
        if (!_maskShape) {
            _maskShape = [CAShapeLayer layer];
            _maskShape.path = shape.path;
            _maskShape.strokeColor = nil;
            _maskShape.fillColor = [UIColor blackColor].CGColor;
        }
        
        if ([self.fill canBeAppliedToGradientLayer]) {
            [_fillView removeFromSuperview];
            _fillView = nil;
            
            self.layer.backgroundColor = [UIColor clearColor].CGColor;
            if (!_gradientLayer) {
                _gradientLayer = [CAGradientLayer layer];
                [self.layer addSublayer:_gradientLayer];
                _gradientLayer.mask = _maskShape;
            }
            [self.fill applyToLayer:self.gradientLayer];
        } else if (fill) {
            [_gradientLayer removeFromSuperlayer];
            _gradientLayer = nil;
            if (!_fillView) {
                _fillView = [_FillView new];
                [self addSubview:_fillView];
                _fillView.layer.mask = self.maskShape;
            }
            _fillView.fill = fill;
        }
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.fillView.frame = self.bounds;
    self.gradientLayer.frame = self.bounds;
    self.maskShape.frame = self.bounds;
}

#pragma mark Strokes
- (void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
    [self updateStroke];
}

- (void)setStrokeWidth:(CGFloat)strokeWidth {
    _strokeWidth = strokeWidth;
    [self updateStroke];
}

- (void)updateStroke {
    CAShapeLayer *shape = (id)self.layer;
    shape.strokeColor = self.strokeColor.CGColor;
    shape.lineWidth = self.strokeWidth;
}

@end
