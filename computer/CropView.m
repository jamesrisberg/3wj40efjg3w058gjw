//
//  CropView.m
//  computer
//
//  Created by Nate Parrott on 10/23/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CropView.h"

typedef NS_OPTIONS(NSInteger, _CropViewGrabbed) {
    _CropViewGrabbedNone = 0,
    _CropViewGrabbedLeft = 1 << 1,
    _CropViewGrabbedTop = 1 << 2,
    _CropViewGrabbedRight = 1 << 3,
    _CropViewGrabbedBottom = 1 << 4
};

@interface CropView () {
    UIView *_top, *_bottom, *_left, *_right;
    CGRect _boundsWhenCropLastSet;
    _CropViewGrabbed _grabbed;
    NSMutableSet *_touchesDown;
    CGRect _prevMultitouchBoundingBox;
}

@end

@implementation CropView

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    self.multipleTouchEnabled = YES;
}

- (void)setBounds:(CGRect)bounds {
    CGRect oldBounds = self.bounds;
    [super setBounds:bounds];
    if (oldBounds.size.width == 0 || oldBounds.size.height == 0) { // set default crop rect
        
    } else { // scale crop rect
        CGFloat sx = bounds.size.width / oldBounds.size.width;
        CGFloat sy = bounds.size.height / oldBounds.size.height;
        self.cropRect = CGRectMake(self.cropRect.origin.x * sx, self.cropRect.origin.y * sy, self.cropRect.size.width * sx, self.cropRect.size.height * sy);
    }
}

- (void)setCropRect:(CGRect)cropRect {
    _cropRect = cropRect;
    if (!_top) {
        _top = [UIView new];
        _bottom = [UIView new];
        _left = [UIView new];
        _right = [UIView new];
        for (UIView *v in @[_top, _bottom, _left, _right]) {
            v.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.7];
            [self addSubview:v];
        }
    }
    _boundsWhenCropLastSet = self.bounds;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, _boundsWhenCropLastSet) && _boundsWhenCropLastSet.size.width * _boundsWhenCropLastSet.size.height > 0) {
        // scale crop rect:
        CGFloat sx = self.bounds.size.width / _boundsWhenCropLastSet.size.width;
        CGFloat sy = self.bounds.size.height / _boundsWhenCropLastSet.size.height;
        self.cropRect = CGRectMake(self.cropRect.origin.x * sx, self.cropRect.origin.y * sy, self.cropRect.size.width * sx, self.cropRect.size.height * sy);
        _boundsWhenCropLastSet = self.bounds;
    }
    
    _top.frame = CGRectMake(0, 0, self.bounds.size.width, self.cropRect.origin.y);
    _bottom.frame = CGRectMake(0, CGRectGetMaxY(self.cropRect), self.bounds.size.width, self.bounds.size.height - CGRectGetMaxY(self.cropRect));
    _left.frame = CGRectMake(0, CGRectGetMaxY(_top.frame), self.cropRect.origin.x, _bottom.frame.origin.y - CGRectGetMaxY(_top.frame));
    _right.frame = CGRectMake(CGRectGetMaxX(self.cropRect), CGRectGetMaxY(_top.frame), self.bounds.size.width - CGRectGetMaxX(self.cropRect), _bottom.frame.origin.y - CGRectGetMaxY(_top.frame));
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_touchesDown) _touchesDown = [NSMutableSet new];
    for (UITouch *t in touches) [_touchesDown addObject:t];
    if (_touchesDown.count == 1) {
        CGPoint pos = [[_touchesDown anyObject] locationInView:self];
        CGFloat grabberThreshold = 30;
        _grabbed = _CropViewGrabbedNone;
        if (fabs(CGRectGetMinX(self.cropRect) - pos.x) < grabberThreshold) _grabbed |= _CropViewGrabbedLeft;
        if (fabs(CGRectGetMaxX(self.cropRect) - pos.x) < grabberThreshold) _grabbed |= _CropViewGrabbedRight;
        if (fabs(CGRectGetMinY(self.cropRect) - pos.y) < grabberThreshold) _grabbed |= _CropViewGrabbedTop;
        if (fabs(CGRectGetMaxY(self.cropRect) - pos.y) < grabberThreshold) _grabbed |= _CropViewGrabbedBottom;
        if (_grabbed == _CropViewGrabbedNone && CGRectContainsPoint(self.cropRect, pos)) {
            _grabbed = _CropViewGrabbedLeft | _CropViewGrabbedRight | _CropViewGrabbedTop | _CropViewGrabbedBottom;
        }
    } else if (_touchesDown.count == 2) {
        _prevMultitouchBoundingBox = [self boundingBoxForTouches:_touchesDown];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGRect cropRect = self.cropRect;
    if (_touchesDown.count == 1) {
        CGPoint pos = [_touchesDown.anyObject locationInView:self];
        CGPoint oldPos = [_touchesDown.anyObject previousLocationInView:self];
        CGPoint delta = CGPointMake(pos.x - oldPos.x, pos.y - oldPos.y);
        
        if (_grabbed & _CropViewGrabbedLeft) {
            cropRect.origin.x += delta.x;
            cropRect.size.width -= delta.x;
        }
        if (_grabbed & _CropViewGrabbedRight) {
            cropRect.size.width += delta.x;
        }
        if (_grabbed & _CropViewGrabbedTop) {
            cropRect.origin.y += delta.y;
            cropRect.size.height -= delta.y;
        }
        if (_grabbed & _CropViewGrabbedBottom) {
            cropRect.size.height += delta.y;
        }
    } else if (_touchesDown.count == 2) {
        CGRect bbox = [self boundingBoxForTouches:_touchesDown];
        CGFloat shiftLeft = CGRectGetMinX(bbox) - CGRectGetMinX(_prevMultitouchBoundingBox);
        CGFloat shiftRight = CGRectGetMaxX(bbox) - CGRectGetMaxX(_prevMultitouchBoundingBox);
        CGFloat shiftTop = CGRectGetMinY(bbox) - CGRectGetMinY(_prevMultitouchBoundingBox);
        CGFloat shiftBottom = CGRectGetMaxY(bbox) - CGRectGetMaxY(_prevMultitouchBoundingBox);
        cropRect.origin.x += shiftLeft;
        cropRect.size.width += shiftRight - shiftLeft;
        cropRect.origin.y += shiftTop;
        cropRect.size.height += shiftBottom - shiftTop;
        _prevMultitouchBoundingBox = bbox;
    }
    self.cropRect = cropRect;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) [_touchesDown removeObject:t];
    if (_touchesDown.count == 0) _grabbed = _CropViewGrabbedNone;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (CGRect)boundingBoxForTouches:(NSSet<__kindof UITouch*> *)touches {
    CGFloat minX = MAXFLOAT;
    CGFloat minY = MAXFLOAT;
    CGFloat maxX = -MAXFLOAT;
    CGFloat maxY = -MAXFLOAT;
    for (UITouch *touch in touches) {
        CGPoint p = [touch locationInView:self];
        minX = MIN(minX, p.x);
        minY = MIN(minY, p.y);
        maxX = MAX(maxX, p.x);
        maxY = MAX(maxY, p.y);
    }
    return CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

@end
