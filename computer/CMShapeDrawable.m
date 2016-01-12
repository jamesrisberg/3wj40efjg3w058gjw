//
//  CMShapeDrawable.m
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMShapeDrawable.h"
#import "computer-Swift.h"
#import "StrokePickerViewController.h"

@interface _CMGradientView : UIView
@end
@implementation _CMGradientView
+ (Class)layerClass {
    return [CAGradientLayer class];
}
@end

@implementation _CMShapeView

+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (void)setPatternView:(UIView *)patternView {
    if (patternView == _patternView) return;
    [_patternView removeFromSuperview];
    
    _patternView = patternView;
    if (patternView) {
        CAShapeLayer *shape = (id)self.layer;
        [self addSubview:patternView];
        if (!_maskShape) {
            _maskShape = [CAShapeLayer layer];
            _maskShape.strokeColor = nil;
            _maskShape.fillColor = [UIColor blackColor].CGColor;
            _maskShape.path = shape.path;
        }
        patternView.layer.mask = _maskShape;
    } else {
        _maskShape = nil;
    }
}

- (void)setPattern:(Pattern *)pattern {
    if ([_pattern isEqual:pattern]) return;
    _pattern = pattern;
    
    CAShapeLayer *shape = (id)self.layer;
    
    UIColor *solidColor = [pattern solidColorOrPattern];
    if (solidColor) {
        self.patternView = nil;
        shape.fillColor = solidColor.CGColor;
        return;
    }
    
    if ([pattern canApplyToGradientLayer]) {
        _CMGradientView *gradientView = [self.patternView isKindOfClass:[_CMGradientView class]] ? (id)self.patternView : [_CMGradientView new];
        [pattern applyToGradientLayer:(CAGradientLayer *)gradientView.layer];
        self.patternView = gradientView;
        return;
    }
    
    if ([pattern canApplyToImageView]) {
        UIImageView *imageView = [self.pattern isKindOfClass:[UIImageView class]] ? (id)self.patternView : [UIImageView new];
        [pattern applyToImageView:imageView];
        self.patternView = imageView;
        return;
    }
    
    self.patternView = nil;
    self.backgroundColor = [UIColor clearColor];
    shape.fillColor = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.patternView.frame = self.bounds;
    self.maskShape.frame = self.bounds;
}

@end

@implementation CMShapeDrawable

- (instancetype)init {
    self = [super init];
    self.aspectRatio = 1;
    self.pattern = [Pattern solidColor:[UIColor clearColor]];
    self.strokeWidth = 0;
    self.strokePattern = [Pattern solidColor:[UIColor blackColor]];
    return self;
}

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObjectsFromArray:@[@"strokeWidth", @"strokePattern", @"pattern", @"path", @"aspectRatio"]];
}

- (UIView *)renderToView:(UIView *)existingOrNil context:(CMRenderContext *)ctx {
    FrameTime *time = ctx.time;
    _CMShapeView *shapeView = [existingOrNil isKindOfClass:[_CMShapeView class]] ? (id)existingOrNil : [_CMShapeView new];
    
    [super renderToView:shapeView context:ctx];
    
    UIBezierPath *path = self.path.copy;
    CGRect pathBounds = path.bounds;
    [path applyTransform:CGAffineTransformMakeTranslation(-pathBounds.origin.x, -pathBounds.origin.y)];
    [path applyTransform:CGAffineTransformMakeScale(shapeView.bounds.size.width / pathBounds.size.width, shapeView.bounds.size.height / pathBounds.size.height)];
    // [path applyTransform:CGAffineTransformMakeScale(shapeView.bounds.size.width/2, shapeView.bounds.size.height/2)];
    
    CMShapeDrawableKeyframe *keyframe = [self.keyframeStore interpolatedKeyframeAtTime:time];
    CAShapeLayer *shapeLayer = (id)shapeView.layer;
    shapeLayer.path = path.CGPath;
    shapeLayer.strokeColor = self.strokePattern.primaryColor.CGColor;
    shapeLayer.lineWidth = self.strokeWidth * keyframe.strokeScale;
    shapeLayer.path = path.CGPath;
    shapeLayer.strokeStart = keyframe.strokeStart;
    shapeLayer.strokeEnd = keyframe.strokeEnd;
    shapeView.pattern = self.pattern;
    shapeView.maskShape.path = path.CGPath;
    return shapeView;
}

- (NSArray<PropertyModel*>*)uniqueObjectPropertiesWithEditor:(CanvasEditor *)editor {
    PropertyModel *fill = [PropertyModel new];
    fill.type = PropertyModelTypeFill;
    fill.key = @"pattern";
    fill.title = NSLocalizedString(@"Fill", @"");
    
    PropertyModel *strokeWidth = [PropertyModel new];
    strokeWidth.title = NSLocalizedString(@"Stroke", @"");
    strokeWidth.key = @"strokeWidth";
    strokeWidth.valueMax = 10;
    strokeWidth.type = PropertyModelTypeSlider;
    
    PropertyModel *strokeColor = [PropertyModel new];
    // strokeColor.title = NSLocalizedString(@"Stroke color", @"");
    strokeColor.key = @"strokePattern";
    strokeColor.type = PropertyModelTypeColor;
    
    return [@[fill, strokeWidth, strokeColor] arrayByAddingObjectsFromArray:[super uniqueObjectPropertiesWithEditor:editor]];
}

- (NSArray<PropertyModel*>*)animatablePropertiesWithEditor:(CanvasEditor *)editor {
    PropertyModel *strokeScale = [PropertyModel new];
    strokeScale.type = PropertyModelTypeSlider;
    strokeScale.title = NSLocalizedString(@"Stroke width multiplier", @"");
    strokeScale.key = @"strokeScale";
    strokeScale.isKeyframeProperty = YES;
    strokeScale.valueMin = 0;
    strokeScale.valueMax = 10;
    
    PropertyModel *strokeStart = [PropertyModel new];
    strokeStart.title = NSLocalizedString(@"Stroke start", @"");
    strokeStart.key = @"strokeStart";
    PropertyModel *strokeEnd = [PropertyModel new];
    strokeEnd.title = NSLocalizedString(@"Stroke end", @"");
    strokeEnd.key = @"strokeEnd";
    for (PropertyModel *model in @[strokeStart, strokeEnd]) {
        model.valueMax = 1;
        model.isKeyframeProperty = YES;
        model.type = PropertyModelTypeSlider;
    }
    
    return [[super animatablePropertiesWithEditor:editor] arrayByAddingObjectsFromArray:@[strokeScale, strokeStart, strokeEnd]];
}

- (Class)keyframeClass {
    return [CMShapeDrawableKeyframe class];
}

- (NSString *)drawableTypeDisplayName {
    return NSLocalizedString(@"Shape", @"");
}

- (void)setPath:(UIBezierPath *)path usingTransactionStack:(CMTransactionStack *)stack updateAspectRatio:(BOOL)updateAspect {
    UIBezierPath *oldPath = self.path;
    CGFloat oldAspectRatio = self.aspectRatio;
    [stack doTransaction:[[CMTransaction alloc] initWithTarget:self action:^(id target) {
        self.path = path;
        CGRect bounds = path.bounds;
        if (updateAspect) {
            self.aspectRatio = bounds.size.height ? bounds.size.width / bounds.size.height : 1;
        } else {
            self.aspectRatio = oldAspectRatio;
        }
    } undo:^(id target) {
        self.path = oldPath;
        self.aspectRatio = oldAspectRatio;
    }]];
}

@end

@implementation CMShapeDrawableKeyframe

- (instancetype)init {
    self = [super init];
    self.strokeScale = 1;
    self.strokeEnd = 1;
    return self;
}

- (NSArray<NSString*>*)keys {
    return [[super keys] arrayByAddingObjectsFromArray:@[@"strokeScale", @"strokeStart", @"strokeEnd"]];
}

@end
