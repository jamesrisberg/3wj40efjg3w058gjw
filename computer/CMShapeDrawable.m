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



@interface _CMShapeView : CMDrawableView

@property (nonatomic) UIView *patternView; // only set if needed
@property (nonatomic) CAShapeLayer *maskShape; // only set if needed for patternView
@property (nonatomic) Pattern *pattern;

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

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObjectsFromArray:@[@"strokeWidth", @"strokeColor", @"pattern", @"path"]];
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
    shapeLayer.strokeColor = self.strokeColor.CGColor;
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
    strokeWidth.title = NSLocalizedString(@"Stroke width", @"");
    strokeWidth.key = @"strokeWidth";
    strokeWidth.valueMax = 10;
    strokeWidth.type = PropertyModelTypeSlider;
    
    PropertyModel *strokeColor = [PropertyModel new];
    strokeColor.title = NSLocalizedString(@"Stroke color", @"");
    strokeColor.key = @"strokeColor";
    strokeColor.type = PropertyModelTypeColor;
    
    return [[super uniqueObjectPropertiesWithEditor:editor] arrayByAddingObjectsFromArray:@[fill, strokeColor, strokeWidth]];
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
    PropertyModel *strokeEnd = [PropertyModel new];
    strokeEnd.title = NSLocalizedString(@"Stroke end", @"");
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

- (void)editStrokeWithEditor:(CanvasEditor *)editor {
    __block CMTransaction *t = nil;
    
    StrokePickerViewController *picker = [StrokePickerViewController new];
    picker.color = self.strokeColor;
    picker.width = self.strokeWidth;
    __weak CMShapeDrawable *weakSelf = self;
    picker.onChange = ^(CGFloat width, UIColor *color) {
        if (!t || t.finalized) {
            CGFloat oldWidth = weakSelf.strokeWidth;
            UIColor *oldColor = weakSelf.strokeColor;
            t = [[CMTransaction alloc] initImplicitlyFinalizaledWhenTouchesEndWithTarget:editor action:^(id target) {
                weakSelf.strokeWidth = width;
                weakSelf.strokeColor = color;
            } undo:^(id target) {
                weakSelf.strokeWidth = oldWidth;
                weakSelf.strokeColor = oldColor;
            }];
            [editor.transactionStack doTransaction:t];
        } else {
            t.action = ^(id target) {
                weakSelf.strokeWidth = width;
                weakSelf.strokeColor = color;
            };
        }
        
        weakSelf.strokeColor = color;
        weakSelf.strokeWidth = width;
    };
    [NPSoftModalPresentationController presentViewController:picker];
}

- (NSString *)drawableTypeDisplayName {
    return NSLocalizedString(@"Shape", @"");
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
