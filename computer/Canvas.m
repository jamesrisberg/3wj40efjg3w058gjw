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
#import "ConvenienceCategories.h"
#import "SubcanvasDrawable.h"

@interface Canvas () {
    BOOL _setup;
    NSMutableSet *_touches;
    NSTimer *_singleTouchPressTimer;
    CGPoint _positionAtStartOfSingleTouchTimer;
    BOOL _currentGestureTransformsDrawableAboutTouchPoint;
    __weak Drawable *_selectionAfterFirstTap;
    CGRect _previousTouchBoundsInSelection;
}

@end

@implementation Canvas

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self setup];
    return self;
}

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
    if (!self.time) self.time = [[FrameTime alloc] initWithFrame:0 atFPS:1];
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
    if (self.selection) {
        _previousTouchBoundsInSelection = [self boundingRectForTouchesUsingCoordinateSpaceOfView:self.selection];
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
        [self.selection updatedKeyframeProperties];
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
        
        [self.selection updatedKeyframeProperties];
    } else if (_touches.count == 3) {
        if (self.selection) {
            CGRect touchBounds = [self boundingRectForTouchesUsingCoordinateSpaceOfView:self.selection];
            CGSize internalSize = CGSizeMake(self.selection.bounds.size.width + touchBounds.size.width - _previousTouchBoundsInSelection.size.width, self.selection.bounds.size.height + touchBounds.size.height - _previousTouchBoundsInSelection.size.height);
            [self.selection setInternalSize:internalSize];
            [self.selection updatedKeyframeProperties];
            _previousTouchBoundsInSelection = touchBounds;
            
            [self.selection updatedKeyframeProperties];
        }
    }
    [self.delegate canvasSelectionRectNeedsUpdate:self];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (id touch in touches) [_touches removeObject:touch];
    if (_touches.count == 0) {
        if ([_singleTouchPressTimer isValid]) {
            // we're still in a valid single press;
            self.selection = [self doHitTest:[touches.anyObject locationInView:self]];
            if ([[touches anyObject] tapCount] == 1) {
                _selectionAfterFirstTap = self.selection;
            }
            if ([[touches anyObject] tapCount] == 2 && self.selection == _selectionAfterFirstTap) {
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
    UIView *topView = [self allHitsAtPoint:[_touches.anyObject locationInView:self]].lastObject;
    self.editorShapeStackList.drawables = [self allItemsOverlappingView:topView];
    [self.editorShapeStackList show];
}

- (CGRect)boundingRectForTouchesUsingCoordinateSpaceOfView:(UIView *)view {
    CGPoint p1 = [[_touches anyObject] locationInView:view];
    CGRect rect = CGRectMake(p1.x, p1.y, 0, 0);
    for (UITouch *touch in _touches) {
        CGPoint p = [touch locationInView:view];
        CGRect r = CGRectMake(p.x, p.y, 0, 0);
        rect = CGRectUnion(rect, r);
    }
    return rect;
}

- (NSArray<__kindof Drawable*>*)drawables {
    return [self.subviews map:^id(id obj) {
        if ([obj isKindOfClass:[Drawable class]]) {
            return obj;
        } else {
            return nil;
        }
    }];
}

#pragma mark Selection

- (void)setSelection:(Drawable *)selection {
    _selection.onShapeUpdate = nil;
    _selection = selection;
    __weak Canvas *weakSelf = self;
    _selection.onShapeUpdate = ^{
        [weakSelf.delegate canvasSelectionRectNeedsUpdate:weakSelf];
    };
    [self.delegate canvasDidChangeSelection:self];
    [self.delegate canvasSelectionRectNeedsUpdate:self];
}

#pragma mark Geometry

- (NSArray *)allHitsAtPoint:(CGPoint)pos {
    CGFloat centerLeeway = 20; // for small objects
    NSMutableArray *hits = [NSMutableArray new];
    for (Drawable *d in self.subviews.reverseObjectEnumerator) {
        // TODO: take into account transforms; don't use UIView's own math
        if ([d pointInside:[d convertPoint:pos fromView:self] withEvent:nil]) {
            [hits addObject:d];
        } else if (CGPointDistance(pos, d.center) < centerLeeway) {
            [hits addObject:d];
        }
    }
    return hits;
}

- (NSArray *)allItemsOverlappingView:(UIView *)view {
    NSMutableArray *hits = [NSMutableArray new];
    for (Drawable *d in self.subviews.reverseObjectEnumerator) {
        if (![d isKindOfClass:[Drawable class]]) continue;
        if (CGRectIntersectsRect(view.frame, d.frame)) { // TODO: fuck transform math
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

- (void)_addDrawableToCanvas:(Drawable *)drawable {
    [self _addDrawableToCanvas:drawable aboveDrawable:nil];
}

- (void)_addDrawableToCanvas:(Drawable *)drawable aboveDrawable:(Drawable *)other {
    if (other) {
        [self insertSubview:drawable aboveSubview:other];
    } else {
        [self addSubview:drawable];
    }
    drawable.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    __weak Canvas *weakSelf = self;
    __weak Drawable *weakDrawable = drawable;
    drawable.onKeyframePropertiesUpdated = ^{
        [weakSelf.delegate canvasDidUpdateKeyframesForCurrentTime:weakSelf];
        [weakSelf updateDrawableForCurrentTime:weakDrawable];
    };
}

#pragma mark Actions

- (void)insertDrawable:(Drawable *)drawable {
    [self _addDrawableToCanvas:drawable];
    drawable.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    
    BOOL animate = !!self.window;
    if (animate) {
        CGFloat scaleFactor = 1.6;
        drawable.scale *= scaleFactor;
        CGFloat oldAlpha = drawable.alpha;
        drawable.alpha = 0;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            drawable.scale /= scaleFactor;
            drawable.alpha = oldAlpha;
        } completion:^(BOOL finished) {
            
        }];
    }
    
    self.selection = drawable;
    [drawable updatedKeyframeProperties];
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    // deliberately DON'T call super
    [aCoder encodeObject:[self drawables] forKey:@"drawables"];
    [aCoder encodeObject:self.time forKey:@"time"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self initWithFrame:CGRectZero]; // deliberately DON'T call super
    for (Drawable *d in [aDecoder decodeObjectForKey:@"drawables"]) {
        [self _addDrawableToCanvas:d];
    }
    self.time = [aDecoder decodeObjectForKey:@"time"];
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

- (id)copy {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

#pragma mark Time
- (void)setTime:(FrameTime *)time {
    _time = time;
    for (Drawable *d in [self drawables]) {
        [self updateDrawableForCurrentTime:d];
    }
    [self.delegate canvasSelectionRectNeedsUpdate:self];
}

- (void)updateDrawableForCurrentTime:(Drawable *)d {
    FrameTime *time = self.time;
    Keyframe *exactKeyframe = [d.keyframeStore keyframeAtTime:time];
    d.dimmed = !exactKeyframe && !self.overrideDimming;
    d.currentKeyframeProperties = [d.keyframeStore interpolatedPropertiesAtTime:time];
    d.timeForStaticAnimations = _useTimeForStaticAnimations ? time.time : -1;
    if ([d isKindOfClass:[SubcanvasDrawable class]]) {
        [(SubcanvasDrawable *)d subcanvas].time = time;
        [(SubcanvasDrawable *)d subcanvas].overrideDimming = self.overrideDimming;
    }
}

- (void)setUseTimeForStaticAnimations:(BOOL)useTimeForStaticAnimations {
    _useTimeForStaticAnimations = useTimeForStaticAnimations;
    for (Drawable *d in [self drawables]) {
        if ([d isKindOfClass:[SubcanvasDrawable class]]) {
            [(SubcanvasDrawable *)d subcanvas].useTimeForStaticAnimations = useTimeForStaticAnimations;
        }
    }
    [self setTime:self.time]; // trigger update of [drawables].timeForStaticAnimations
}

- (void)setOverrideDimming:(BOOL)overrideDimming {
    _overrideDimming = overrideDimming;
    [self setTime:self.time];
}

- (FrameTime *)duration {
    FrameTime *t = [[FrameTime alloc] initWithFrame:1 atFPS:1];
    for (Drawable *d in self.drawables) {
        t = [[d.keyframeStore maxTime] maxWith:t];
        if ([d isKindOfClass:[SubcanvasDrawable class]]) {
            Canvas *sub = [(SubcanvasDrawable *)d subcanvas];
            t = [t maxWith:[sub duration]];
        }
    }
    return t;
}

#pragma mark Layout

- (void)resizeBoundsToFitContent {
    if (self.drawables.count > 0) {
        CGFloat minX = MAXFLOAT;
        CGFloat minY = MAXFLOAT;
        CGFloat maxX = -MAXFLOAT;
        CGFloat maxY = -MAXFLOAT;
        for (Drawable *d in self.drawables) {
            CGFloat radius = MAX(d.bounds.size.width, d.bounds.size.height) / 2 * d.scale * sqrt(2);
            minX = MIN(minX, d.center.x - radius);
            minY = MIN(minY, d.center.y - radius);
            maxX = MAX(maxX, d.center.x + radius);
            maxY = MAX(maxY, d.center.y + radius);
        }
        CGFloat width = MAX(1, maxX - minX);
        CGFloat height = MAX(1, maxY - minY);
        self.bounds = CGRectMake(0, 0, width, height);
        for (Drawable *d in self.drawables) {
            [d.keyframeStore changePropertyAcrossTime:@"center" block:^id(id val) {
                CGPoint c = [val CGPointValue];
                return [NSValue valueWithCGPoint:CGPointMake(c.x - minX, c.y - minY)];
            }];
            d.center = [[d.keyframeStore interpolatedPropertiesAtTime:self.time][@"center"] CGPointValue];
        }
    } else {
        self.bounds = CGRectMake(0, 0, 1, 1);
    }
}

@end
