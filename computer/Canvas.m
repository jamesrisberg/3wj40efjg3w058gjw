//
//  Canvas.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Canvas.h"
#import "Drawable.h"
#import "CGPointExtras.h"
#import "ShapeStackList.h"

@interface Canvas () {
    BOOL _setup;
    NSMutableSet *_touches;
    NSTimer *_singleTouchPressTimer;
    CGPoint _positionAtStartOfSingleTouchTimer;
    BOOL _currentGestureTransformsDrawableAboutTouchPoint;
}

@end

@implementation Canvas

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (!_setup) {
        _setup = YES;
        [self setup];
    }
}

- (void)setup {
    _touches = [NSMutableSet new];
    self.multipleTouchEnabled = YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    BOOL hadZeroTouches = _touches.count == 0;
    [_touches addObjectsFromArray:touches.allObjects];
    if (hadZeroTouches && _touches.count == 1) {
        // this was the first touch down
        _singleTouchPressTimer = [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(longPress) userInfo:nil repeats:NO];
        _positionAtStartOfSingleTouchTimer = [[touches anyObject] locationInView:self];
    }
    if (_touches.count > 1) {
        [_singleTouchPressTimer invalidate];
        NSArray *down = _touches.allObjects;
        CGPoint touchMidpoint = CGPointMidpoint([down[0] locationInView:self], [down[1] locationInView:self]);
        _currentGestureTransformsDrawableAboutTouchPoint = [self.selection pointInside:[self.selection convertPoint:touchMidpoint fromView:self] withEvent:nil];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_singleTouchPressTimer) {
        CGPoint pos = [[touches anyObject] locationInView:self];
        CGFloat dist = sqrt(pow(pos.x - _positionAtStartOfSingleTouchTimer.x, 2) + pow(pos.y - _positionAtStartOfSingleTouchTimer.y, 2));
        if (dist > 5) {
            [_singleTouchPressTimer invalidate];
            _singleTouchPressTimer = nil;
        }
    }
    NSArray *down = _touches.allObjects;
    CGPoint t1 = [down[0] locationInView:self];
    CGPoint t1prev = [down[0] previousLocationInView:self];
    if (_touches.count == 1) {
        self.selection.center = CGPointMake(self.selection.center.x + t1.x - t1prev.x, self.selection.center.y + t1.y - t1prev.y);
    } else if (_touches.count == 2) {
        CGPoint t2 = [down[1] locationInView:self];
        CGPoint t2prev = [down[1] previousLocationInView:self];
        CGFloat rotation = atan2(t2.y - t1.y, t2.x - t1.x);
        CGFloat prevRotation = atan2(t2prev.y - t1prev.y, t2prev.x - t1prev.x);
        CGFloat scale = sqrt(pow(t2.x - t1.x, 2) + pow(t2.y - t1.y, 2));
        CGFloat prevScale = sqrt(pow(t2prev.x - t1prev.x, 2) + pow(t2prev.y - t1prev.y, 2));
        CGPoint pos = CGPointMake((t1.x + t2.x)/2, (t1.y + t2.y)/2);
        CGPoint prevPos = CGPointMake((t1prev.x + t2prev.x)/2, (t1prev.y + t2prev.y)/2);
        CGFloat toRotate = rotation - prevRotation;
        CGFloat toScale = scale / prevScale;
        self.selection.rotation += toRotate;
        self.selection.scale *= toScale;
        
        if (_currentGestureTransformsDrawableAboutTouchPoint) {
            CGPoint touchMidpoint = CGPointMidpoint([down[0] locationInView:self], [down[1] locationInView:self]);
            CGPoint drawableOffset = CGPointMake(self.selection.center.x - touchMidpoint.x, self.selection.center.y - touchMidpoint.y);
            drawableOffset = CGPointScale(drawableOffset, toScale);
            CGFloat offsetAngle = CGPointAngleBetween(CGPointZero, drawableOffset);
            CGFloat offsetDistance = CGPointDistance(CGPointZero, drawableOffset);
            drawableOffset = CGPointShift(CGPointZero, offsetAngle + toRotate, offsetDistance);
            self.selection.center = CGPointAdd(touchMidpoint, drawableOffset);
        }
        
        self.selection.center = CGPointMake(self.selection.center.x + pos.x - prevPos.x, self.selection.center.y + pos.y - prevPos.y);
    }
    // TODO: three-finger aspect-ratio-insensitive scaling
    self.selectionRectNeedUpdate();
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (id touch in touches) [_touches removeObject:touch];
    if (_touches.count == 0) {
        if ([_singleTouchPressTimer isValid]) {
            // we're still in a valid single press;
            self.selection = [self doHitTest:[touches.anyObject locationInView:self]];
            if ([[touches anyObject] tapCount] == 2) {
                [self.selection primaryEditAction];
            }
        }
        [_singleTouchPressTimer invalidate];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (id touch in touches) [_touches removeObject:touch];
    if (_touches.count == 0) {
        [_singleTouchPressTimer invalidate];
    }
}

- (void)longPress {
    self.editorShapeStackList.drawables = [self allHitsAtPoint:[_touches.anyObject locationInView:self]];
    [self.editorShapeStackList show];
}

#pragma mark Selection

- (void)setSelection:(Drawable *)selection {
    _selection = selection;
    self.selectionRectNeedUpdate();
    [UIView animateWithDuration:0.05 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut animations:^{
        selection.scale *= 0.94;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            selection.scale /= 0.94;
        } completion:^(BOOL finished) {
            
        }];
    }];
}

#pragma mark Geometry

- (NSArray *)allHitsAtPoint:(CGPoint)pos {
    NSMutableArray *hits = [NSMutableArray new];
    for (Drawable *d in self.subviews.reverseObjectEnumerator) {
        // TODO: take into account transforms; don't use UIView's own math
        if ([d pointInside:[d convertPoint:pos fromView:self] withEvent:nil]) {
            [hits addObject:d];
        }
    }
    return hits;
}

- (Drawable *)doHitTest:(CGPoint)pos {
    return [self allHitsAtPoint:pos].firstObject;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return self;
}

#pragma mark Actions

- (void)insertDrawable:(Drawable *)drawable {
    [self addSubview:drawable];
    drawable.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    CGFloat scaleFactor = 1.6;
    drawable.scale *= scaleFactor;
    CGFloat oldAlpha = drawable.alpha;
    drawable.alpha = 0;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        drawable.scale /= scaleFactor;
        drawable.alpha = oldAlpha;
    } completion:^(BOOL finished) {
        
    }];
    self.selection = drawable;
}

@end
