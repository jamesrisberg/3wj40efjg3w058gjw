//
//  CMShapeDrawable.m
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMShapeDrawable.h"
#import "computer-Swift.h"

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
    CAShapeLayer *shapeLayer = (id)shapeView.layer;
    shapeLayer.strokeColor = self.strokeColor.CGColor;
    shapeLayer.lineWidth = self.strokeWidth;
    shapeLayer.path = self.path.CGPath;
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

- (NSArray<__kindof OptionsViewCellModel*>*)optionsViewCellModelsWithEditor:(CanvasEditor *)editor {
    return [super optionsViewCellModelsWithEditor:editor];
}

@end
