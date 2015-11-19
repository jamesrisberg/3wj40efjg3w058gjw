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

#define HIT_TEST_CENTER_LEEWAY 27
#define TAP_STACK_REUSE_MAX_DISTANCE 30
#define TAP_STACK_REUSE_MAX_TIME 2.5

@interface Canvas () {
    BOOL _setup;
    NSMutableSet *_touches;
    BOOL _currentGestureTransformsDrawableAboutTouchPoint;
    __weak Drawable *_selectionAfterFirstTap;
    CGRect _previousTouchBoundsInSelection;
    NSSet *_selectedItems;
    
    NSArray *_tapStack;
    CFAbsoluteTime _tapStackGeneratedAtTime;
    CGPoint _tapStackGeneratedAtPoint;
    
    __weak Drawable *_lastSelection;
    __weak Drawable *_selectionBeforeFirstTap;
}

@property (nonatomic,readonly) Drawable *singleSelection;

@property (nonatomic) CGFloat touchForceFraction;
@property (nonatomic) UIPercentDrivenInteractiveTransition *interactiveOptionsTransition;

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
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)]];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:longPress];
}

- (void)singleTap:(UITapGestureRecognizer *)rec {
    if (rec.state == UIGestureRecognizerStateRecognized) {
        _selectionBeforeFirstTap = self.singleSelection;
        
        CGPoint p = [rec locationInView:self];
        if (CGPointDistance(p, _tapStackGeneratedAtPoint) <= TAP_STACK_REUSE_MAX_DISTANCE && CFAbsoluteTimeGetCurrent() - _tapStackGeneratedAtTime <= TAP_STACK_REUSE_MAX_TIME && _tapStack.count) {
            // reuse the tap stack:
            if (_lastSelection && [_tapStack containsObject:_lastSelection]) {
                NSInteger i = [_tapStack indexOfObject:_lastSelection];
                i = (i+1) % _tapStack.count;
                [self userGesturedToSelectDrawable:_tapStack[i]];
            } else {
                [self userGesturedToSelectDrawable:_tapStack.firstObject];
            }
        } else {
            _tapStack = [self allHitsAtPoint:p];
            [self userGesturedToSelectDrawable:_tapStack.firstObject];
            // TODO: add objects overlapping this view to the end of the tap stack?
        }
        _tapStackGeneratedAtPoint = p;
        _tapStackGeneratedAtTime = CFAbsoluteTimeGetCurrent();
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)rec {
    if (rec.state == UIGestureRecognizerStateRecognized) {
        NSArray *hits = [self allHitsAtPoint:[rec locationInView:self]];
        if (_selectionBeforeFirstTap) {
            if ([hits containsObject:_selectionBeforeFirstTap] || hits.count == 0) {
                [self userGesturedToSelectDrawable:_selectionBeforeFirstTap];
            }
        }
        [self.delegate canvasShowShouldOptions:self withInteractivePresenter:nil touchPos:[rec locationInView:self]];
    }
}

- (void)longPress:(UILongPressGestureRecognizer *)rec {
    if (rec.state == UIGestureRecognizerStateBegan) {
        UIView *topView = [self allHitsAtPoint:[_touches.anyObject locationInView:self]].lastObject;
        self.editorShapeStackList.drawables = [self allItemsOverlappingView:topView];
        [self.editorShapeStackList show];
        [self updateForceReading];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_touches addObjectsFromArray:touches.allObjects];
    if (_touches.count > 1) {
        NSArray *down = _touches.allObjects;
        CGPoint touchMidpoint = CGPointMidpoint([down[0] locationInView:self], [down[1] locationInView:self]);
        _currentGestureTransformsDrawableAboutTouchPoint = [self.singleSelection pointInside:[self.singleSelection convertPoint:touchMidpoint fromView:self] withEvent:nil];
    }
    if (self.singleSelection) {
        _previousTouchBoundsInSelection = [self boundingRectForTouchesUsingCoordinateSpaceOfView:self.singleSelection];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateForceReading];
    
    NSArray *down = _touches.allObjects;
    CGPoint t1 = [down[0] locationInView:self];
    CGPoint t1prev = [down[0] previousLocationInView:self];
    
    CGFloat motionMultiplier = self.touchForceFraction > 0.9 ? 0.4 : 1;
    
    if (_touches.count == 1) {
        self.singleSelection.center = CGPointMake(self.singleSelection.center.x + (t1.x - t1prev.x) * motionMultiplier, self.singleSelection.center.y + (t1.y - t1prev.y) * motionMultiplier);
        [self.singleSelection updatedKeyframeProperties];
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
        self.singleSelection.rotation += toRotate * motionMultiplier;
        self.singleSelection.scale = self.singleSelection.scale * (1-motionMultiplier) + self.singleSelection.scale * toScale * motionMultiplier;
        
        if (_currentGestureTransformsDrawableAboutTouchPoint) {
            CGPoint touchMidpoint = CGPointMidpoint([down[0] locationInView:self], [down[1] locationInView:self]);
            CGPoint drawableOffset = CGPointMake(self.singleSelection.center.x - touchMidpoint.x, self.singleSelection.center.y - touchMidpoint.y);
            drawableOffset = CGPointScale(drawableOffset, toScale);
            CGFloat offsetAngle = CGPointAngleBetween(CGPointZero, drawableOffset);
            CGFloat offsetDistance = CGPointDistance(CGPointZero, drawableOffset);
            drawableOffset = CGPointShift(CGPointZero, offsetAngle + toRotate, offsetDistance);
            self.singleSelection.center = CGPointAdd(touchMidpoint, CGPointScale(drawableOffset, motionMultiplier));
        }
        
        self.singleSelection.center = CGPointMake(self.singleSelection.center.x + (pos.x - prevPos.x) * motionMultiplier, self.singleSelection.center.y + (pos.y - prevPos.y) * motionMultiplier);
        
        [self.singleSelection updatedKeyframeProperties];
    } else if (_touches.count == 3) {
        if (self.singleSelection) {
            CGRect touchBounds = [self boundingRectForTouchesUsingCoordinateSpaceOfView:self.singleSelection];
            CGSize internalSize = CGSizeMake(self.singleSelection.bounds.size.width + touchBounds.size.width - _previousTouchBoundsInSelection.size.width, self.singleSelection.bounds.size.height + touchBounds.size.height - _previousTouchBoundsInSelection.size.height);
            [self.singleSelection setInternalSize:internalSize];
            [self.singleSelection updatedKeyframeProperties];
            _previousTouchBoundsInSelection = touchBounds;
            
            [self.singleSelection updatedKeyframeProperties];
        }
    }
    [self.delegate canvasSelectionRectNeedsUpdate:self];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (id touch in touches) [_touches removeObject:touch];
    [self updateForceReading];
}

- (void)updateForceReading {
    CGFloat maxForce = 0;
    for (UITouch *touch in _touches) {
        CGFloat force = touch.maximumPossibleForce ? touch.force / touch.maximumPossibleForce : 0;
        maxForce = MAX(force, maxForce);
    }
    self.touchForceFraction = maxForce;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (id touch in touches) [_touches removeObject:touch];
    [self updateForceReading];
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

#pragma mark Geometry

- (NSArray *)allHitsAtPoint:(CGPoint)pos {
    CGFloat centerLeeway = 40; // for small objects
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
        weakDrawable.time = weakSelf.time;
        [weakSelf updateDrawableForCurrentTime:weakDrawable];
    };
    [self updateDrawableForCurrentTime:weakDrawable];
}

- (void)_removeDrawable:(Drawable *)d {
    d.onKeyframePropertiesUpdated = nil;
    d.onShapeUpdate = nil;
    [d removeFromSuperview];
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
    self.selectedItems = [NSSet setWithObject:drawable];
    [drawable updatedKeyframeProperties];
}

- (void)createGroup:(id)sender {
    NSArray<__kindof Drawable*> *selection = self.selectedItems.allObjects;
    selection = [selection sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSInteger i1 = [[[obj1 superview] subviews] indexOfObject:obj1];
        NSInteger i2 = [[[obj2 superview] subviews] indexOfObject:obj2];
        return i1 < i2 ? NSOrderedAscending : NSOrderedDescending;
    }];
    if (selection.count > 0) {
        if (selection.count == 1 && [selection.firstObject isKindOfClass:[SubcanvasDrawable class]]) {
            // this is already a group, so don't group it again
        } else {
            // DO IT
            self.selectedItems = [NSSet set];
            CGPoint firstItemPosition = [self convertPoint:selection.firstObject.center fromView:selection.firstObject.superview];
            for (Drawable *d in selection) {
                [self _removeDrawable:d];
            }
            SubcanvasDrawable *group = [SubcanvasDrawable new];
            Canvas *child = [Canvas new];
            for (Drawable *d in selection) {
                [child _addDrawableToCanvas:d];
            }
            group.subcanvas = child;
            [group setInternalSize:child.bounds.size];
            [self _addDrawableToCanvas:group];
            CGPoint firstItemNewPosition = [self convertPoint:selection.firstObject.center fromView:selection.firstObject.superview];
            group.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2); //CGPointMake(group.center.x + firstItemPosition.x - firstItemNewPosition.x, group.center.y + firstItemPosition.y - firstItemNewPosition.y);
            [group updatedKeyframeProperties];
        }
    }
}

- (void)copy:(id)sender {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.selectedItems.allObjects];
    [[UIPasteboard generalPasteboard] setData:data forPasteboardType:DrawableArrayPasteboardType];
}

- (void)paste:(id)sender {
    if ([[UIPasteboard generalPasteboard] containsPasteboardTypes:@[DrawableArrayPasteboardType]]) {
        NSData *data = [[UIPasteboard generalPasteboard] dataForPasteboardType:DrawableArrayPasteboardType];
        NSArray *drawables = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        for (Drawable *d in drawables) {
            [self _addDrawableToCanvas:d]; // TODO: make sure this drawable would be visible onscreen
        }
    }
}

- (void)delete:(id)sender {
    for (Drawable *d in self.selectedItems) {
        [d delete:sender];
    }
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
        d.time = time;
    }
    [self.delegate canvasSelectionRectNeedsUpdate:self];
}

- (void)setUseTimeForStaticAnimations:(BOOL)useTimeForStaticAnimations {
    _useTimeForStaticAnimations = useTimeForStaticAnimations;
    for (Drawable *d in [self drawables]) {
        d.useTimeForStaticAnimations = useTimeForStaticAnimations;
    }
}


- (void)setSuppressTimingVisualizations:(BOOL)suppressTimingVisualizations {
    
}

- (FrameTime *)duration {
    FrameTime *t = [[FrameTime alloc] initWithFrame:1 atFPS:24];
    for (Drawable *d in self.drawables) {
        t = [[d.keyframeStore maxTime] maxWith:t];
        if ([d isKindOfClass:[SubcanvasDrawable class]]) {
            Canvas *sub = [(SubcanvasDrawable *)d subcanvas];
            t = [t maxWith:[sub duration]];
        }
    }
    return t;
}

- (FrameTime *)loopingDuration {
    return nil; // TODO
}

- (void)updateDrawableForCurrentTime:(Drawable *)d {
    d.time = self.time;
    d.suppressTimingVisualizations = self.suppressTimingVisualizations;
    d.useTimeForStaticAnimations = self.useTimeForStaticAnimations;
}

#pragma mark Layout

- (void)resizeBoundsToFitContent {
    if (self.drawables.count > 0) {
        CGFloat minX = MAXFLOAT;
        CGFloat minY = MAXFLOAT;
        CGFloat maxX = -MAXFLOAT;
        CGFloat maxY = -MAXFLOAT;
        for (Drawable *d in self.drawables) {
            for (Keyframe *keyframe in d.keyframeStore.allKeyframes) {
                CGRect bounds = [keyframe.properties[@"bounds"] CGRectValue];
                CGPoint center = [keyframe.properties[@"center"] CGPointValue];
                CGFloat scale = [keyframe.properties[@"scale"] floatValue];
                CGFloat rotation = [keyframe.properties[@"rotation"] floatValue];
                CGRect bbox = NPBoundingBoxOfRotatedRect(bounds.size, center, rotation, scale);
                minX = MIN(minX, bbox.origin.x);
                minY = MIN(minY, bbox.origin.y);
                maxX = MAX(maxX, CGRectGetMaxX(bbox));
                maxY = MAX(maxY, CGRectGetMaxY(bbox));
            }
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

#pragma mark Selection
- (NSSet *)selectedItems {
    return _selectedItems ? : [NSSet set];
}

- (void)setSelectedItems:(NSSet *)selectedItems {
    __weak Canvas *weakSelf = self;
    
    for (Drawable *old in _selectedItems) {
        old.onShapeUpdate = nil;
    }
    
    _selectedItems = selectedItems.copy ? : [NSSet new];
    
    for (Drawable *d in selectedItems) {
        d.onShapeUpdate = ^{
            [weakSelf.delegate canvasSelectionRectNeedsUpdate:weakSelf];
        };
    }
    
    [self.delegate canvasDidChangeSelection:self];
    [self.delegate canvasSelectionRectNeedsUpdate:self];
    
    _lastSelection = selectedItems.anyObject;
}

- (void)setMultipleSelectionEnabled:(BOOL)multipleSelectionEnabled {
    _multipleSelectionEnabled = multipleSelectionEnabled;
    if (!multipleSelectionEnabled && self.selectedItems.count > 1) {
        self.selectedItems = [NSSet setWithObject:self.selectedItems.anyObject];
    }
}

- (void)userGesturedToSelectDrawable:(Drawable *)d {
    NSMutableSet *newSelection = self.selectedItems.mutableCopy;
    if (d == nil) {
        if (!self.multipleSelectionEnabled) {
            [newSelection removeAllObjects];
        }
    } else {
        if (self.multipleSelectionEnabled) {
            if ([newSelection containsObject:d]) {
                [newSelection removeObject:d];
            } else {
                [newSelection addObject:d];
            }
        } else {
            [newSelection removeAllObjects];
            [newSelection addObject:d];
        }
    }
    self.selectedItems = newSelection;
    if ([newSelection containsObject:d]) {
        _lastSelection = d;
    }
}

- (Drawable *)singleSelection {
    if (_selectedItems.count == 1) {
        return _selectedItems.anyObject;
    } else {
        return nil;
    }
}

#pragma mark Force Touch
- (void)setTouchForceFraction:(CGFloat)touchForceFraction {
    _touchForceFraction = touchForceFraction;
    return; // DISABLED
    if (!self.editorShapeStackList.hidden) {
        touchForceFraction = 0;
    }
    CGFloat minForce = 0.3;
    CGFloat maxForce = 1;
    if (touchForceFraction > minForce) {
        if (!self.interactiveOptionsTransition) {
            self.interactiveOptionsTransition = [[UIPercentDrivenInteractiveTransition alloc] init];
            [self.delegate canvasShowShouldOptions:self withInteractivePresenter:self.interactiveOptionsTransition touchPos:CGPointZero];
        }
    }
    if (self.interactiveOptionsTransition) {
        CGFloat percentComplete = MIN(1, (touchForceFraction - minForce) / (maxForce - minForce));
        NSLog(@"Percent: %f", percentComplete);
        CGFloat oldPercentage = self.interactiveOptionsTransition.percentComplete;
        [self.interactiveOptionsTransition updateInteractiveTransition:percentComplete];
        if (self.interactiveOptionsTransition.percentComplete == 1 && oldPercentage < 1) {
            //[_singleTouchPressTimer invalidate];
            //_singleTouchPressTimer = nil;
            [self.interactiveOptionsTransition finishInteractiveTransition];
        }
    }
    if (touchForceFraction < minForce) {
        [self.interactiveOptionsTransition cancelInteractiveTransition];
        self.interactiveOptionsTransition = nil;
    }
}

@end
