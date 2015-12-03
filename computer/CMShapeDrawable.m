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
            _maskShape.path = shape.path;
            _maskShape.strokeColor = nil;
            _maskShape.fillColor = [UIColor blackColor].CGColor;
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

- (UIView *)renderToView:(UIView *)existingOrNil atTime:(FrameTime *)time {
    _CMShapeView *shapeView = [existingOrNil isKindOfClass:[_CMShapeView class]] ? (id)existingOrNil : [_CMShapeView new];
    CMShapeDrawableKeyframe *keyframe = [self.keyframeStore interpolatedKeyframeAtTime:time];
    CAShapeLayer *shapeLayer = (id)shapeView.layer;
    shapeLayer.strokeColor = self.strokeColor.CGColor;
    shapeLayer.lineWidth = self.strokeWidth * keyframe.strokeScale;
    shapeLayer.path = self.path.CGPath;
    shapeLayer.strokeStart = keyframe.strokeStart;
    shapeLayer.strokeEnd = keyframe.strokeEnd;
    shapeView.pattern = self.pattern;
    [super renderToView:shapeView atTime:time];
    return shapeView;
}

- (UIView *)propertiesModalTopActionViewWithEditor:(CanvasEditor *)editor {
    PatternPickerView *picker = [[PatternPickerView alloc] initWithFrame:CGRectMake(0, 0, 10, 44)];
    picker.pattern = self.pattern ? : [Pattern solidColor:[UIColor clearColor]];
    __weak CMShapeDrawable *weakSelf = self;
    
    __block CMTransaction *transaction = nil;
    
    picker.onPatternChanged = ^(Pattern *pattern) {
        weakSelf.pattern = pattern;
        if (!transaction) {
            Pattern *oldPattern = weakSelf.pattern;
            transaction = [[CMTransaction alloc] initNonFinalizedWithTarget:editor action:^(id target) {
                [weakSelf setPattern:pattern];
            } undo:^(id target) {
                [weakSelf setPattern:oldPattern];
            }];
            [editor.transactionStack doTransaction:transaction];
        } else {
            transaction.action = ^(id target) {
                [weakSelf setPattern:pattern];
            };
        }
    };
    picker.onPatternChangeTransactionEnded = ^{
        [transaction setFinalized:YES];
        transaction = nil;
    };
    
    __weak PatternPickerView *weakPicker = picker;
    picker.shouldEditModally = ^{
        [weakPicker editModally:[editor vcForModals]];
    };
    return picker;
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
