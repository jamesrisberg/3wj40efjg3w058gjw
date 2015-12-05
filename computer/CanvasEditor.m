//
//  Canvas.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CanvasEditor.h"
#import "Drawable.h"
#import "CGPointExtras.h"
#import "ShapeStackList.h"
#import "ConvenienceCategories.h"
#import "SubcanvasDrawable.h"
#import "VideoDrawable.h"
#import "computer-Swift.h"
#import "CMDrawable.h"
#import "CMCanvas.h"
#import "CMPhotoDrawable.h"

#define HIT_TEST_CENTER_LEEWAY 27
#define TAP_STACK_REUSE_MAX_DISTANCE 30
#define TAP_STACK_REUSE_MAX_TIME 2.5

@interface CanvasEditor () {
    BOOL _setup;
    NSMutableSet *_touches;
    BOOL _currentGestureTransformsDrawableAboutTouchPoint;
    __weak CMDrawable *_selectionAfterFirstTap;
    CGRect _previousTouchBoundsInSelection;
    NSSet<CMDrawable*> *_selectedItems;
    
    NSArray *_tapStack;
    CFAbsoluteTime _tapStackGeneratedAtTime;
    CGPoint _tapStackGeneratedAtPoint;
    
    __weak CMDrawable *_lastSelection;
    __weak CMDrawable *_selectionBeforeFirstTap;
    CADisplayLink *_displayLink;
    
    CMTransaction *_currentObjectMoveTransaction;
}

@property (nonatomic,readonly) CMDrawable *singleSelection;

@property (nonatomic) CGFloat touchForceFraction;
@property (nonatomic) UIPercentDrivenInteractiveTransition *interactiveOptionsTransition;
@property (nonatomic) BOOL rendering;

@property (nonatomic) _CMCanvasView *canvasView;

@property (nonatomic) CMTransactionStack *transactionStack;

@end

@implementation CanvasEditor

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

- (UIViewController *)vcForModals {
    return [NPSoftModalPresentationController getViewControllerForPresentationInWindow:self.window];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    self.rendering = !!newWindow;
}

- (void)setup {
    self.transactionStack = [CMTransactionStack new];
    
    _touches = [NSMutableSet new];
    self.multipleTouchEnabled = YES;
    if (!self.time) self.time = [[FrameTime alloc] initWithFrame:0 atFPS:1];
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)]];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:longPress];
    
    self.repeatCount = 1;
    self.reboundAnimation = NO;
    
    self.canvas = [CMCanvas new];
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
        [self.delegate canvas:self shouldShowPropertiesViewForDrawables:self.selectedItems.allObjects];
    }
}

- (void)longPress:(UILongPressGestureRecognizer *)rec {
    if (rec.state == UIGestureRecognizerStateBegan) {
        CMDrawable *topDrawable = [self allHitsAtPoint:[_touches.anyObject locationInView:self]].lastObject;
        CMDrawableView *topView = [self.canvasView viewForDrawable:topDrawable];
        self.editorShapeStackList.drawables = [self allItemsOverlappingView:topView];
        [self.editorShapeStackList show];
        [self updateForceReading];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_touches addObjectsFromArray:touches.allObjects];
    
    BOOL hasValidOpenTransaction = !!_currentObjectMoveTransaction && !_currentObjectMoveTransaction.finalized;
    if (!hasValidOpenTransaction && self.singleSelection) {
        CMDrawable *selection = self.singleSelection;
        CMDrawableKeyframe *existingKeyframe = [[self.singleSelection.keyframeStore keyframeAtTime:self.time] copy];
        FrameTime *time = self.time;
        CGFloat oldAspectRatio = selection.aspectRatio;
        CGFloat oldBoundsDiagonal = selection.boundsDiagonal;
        _currentObjectMoveTransaction = [[CMTransaction alloc] initImplicitlyFinalizaledWhenTouchesEndWithTarget:self action:^(id target) {
            
        } undo:^(id target) {
            [selection.keyframeStore removeKeyframeAtTime:time];
            if (existingKeyframe) {
                [selection.keyframeStore storeKeyframe:[existingKeyframe copy]];
            }
            selection.boundsDiagonal = oldBoundsDiagonal;
            if ([selection respondsToSelector:@selector(setAspectRatio:)]) {
                [(id)selection setAspectRatio:oldAspectRatio];
            }
        }];
        [self.transactionStack doTransaction:_currentObjectMoveTransaction];

    }
    
    if (_touches.count > 1) {
        NSArray *down = _touches.allObjects;
        CGPoint touchMidpoint = CGPointMidpoint([down[0] locationInView:self], [down[1] locationInView:self]);
        CMDrawableView *view = [self.canvasView viewForDrawable:self.singleSelection];
        _currentGestureTransformsDrawableAboutTouchPoint = [view pointInside:[view convertPoint:touchMidpoint fromView:self] withEvent:nil];
    }
    if (self.singleSelection) {
        CMDrawableView *view = [self.canvasView viewForDrawable:self.singleSelection];
        _previousTouchBoundsInSelection = [self boundingRectForTouchesUsingCoordinateSpaceOfView:view];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateForceReading];
    
    CMDrawable *singleSelection = self.singleSelection;
    
    NSArray *down = _touches.allObjects;
    CGPoint t1 = [down[0] locationInView:self];
    CGPoint t1prev = [down[0] previousLocationInView:self];
    
    CGFloat motionMultiplier = self.touchForceFraction > 0.9 ? 0.4 : 1;
    
    if (_touches.count == 1) {
        CGPoint translation = CGPointMake((t1.x - t1prev.x) * motionMultiplier, (t1.y - t1prev.y) * motionMultiplier);
        if (!CGPointEqualToPoint(translation, CGPointZero)) {
            CMDrawableKeyframe *selectionKeyframe = [[self.singleSelection.keyframeStore createKeyframeAtTimeIfNeeded:self.time] copy];
            selectionKeyframe.center = CGPointMake(selectionKeyframe.center.x + translation.x, selectionKeyframe.center.y + translation.y);
            
            [_currentObjectMoveTransaction setAction:^(id target){
                [singleSelection.keyframeStore storeKeyframe:selectionKeyframe];
            }];
        }
    } else if (_touches.count == 2) {
        
        CMDrawableKeyframe *selectionKeyframe = [[self.singleSelection.keyframeStore createKeyframeAtTimeIfNeeded:self.time] copy];
        
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
        
        if (toRotate || toScale) {
            selectionKeyframe.rotation += toRotate * motionMultiplier;
            selectionKeyframe.scale = selectionKeyframe.scale * (1-motionMultiplier) + selectionKeyframe.scale * toScale * motionMultiplier;
        }
        
        if (_currentGestureTransformsDrawableAboutTouchPoint) {
            CGPoint touchMidpoint = CGPointMidpoint([down[0] locationInView:self], [down[1] locationInView:self]);
            CGPoint drawableOffset = CGPointMake(selectionKeyframe.center.x - touchMidpoint.x, selectionKeyframe.center.y - touchMidpoint.y);
            drawableOffset = CGPointScale(drawableOffset, toScale);
            CGFloat offsetAngle = CGPointAngleBetween(CGPointZero, drawableOffset);
            CGFloat offsetDistance = CGPointDistance(CGPointZero, drawableOffset);
            drawableOffset = CGPointShift(CGPointZero, offsetAngle + toRotate, offsetDistance);
            selectionKeyframe.center = CGPointAdd(touchMidpoint, CGPointScale(drawableOffset, motionMultiplier));
        }
        
        selectionKeyframe.center = CGPointMake(selectionKeyframe.center.x + (pos.x - prevPos.x) * motionMultiplier, selectionKeyframe.center.y + (pos.y - prevPos.y) * motionMultiplier);
        
        [_currentObjectMoveTransaction setAction:^(id target){
            [singleSelection.keyframeStore storeKeyframe:selectionKeyframe];
        }];
    } else if (_touches.count == 3) {
        if (self.singleSelection) {
            CMDrawableKeyframe *selectionKeyframe = [[self.singleSelection.keyframeStore createKeyframeAtTimeIfNeeded:self.time] copy];
            CMDrawableView *view = [self.canvasView viewForDrawable:self.singleSelection];
            CGRect touchBounds = [self boundingRectForTouchesUsingCoordinateSpaceOfView:view];
            CGSize currentInternalSize = CMSizeWithDiagonalAndAspectRatio(self.singleSelection.boundsDiagonal, self.singleSelection.aspectRatio);
            CGSize newInternalSize = CGSizeMake(currentInternalSize.width + (touchBounds.size.width - _previousTouchBoundsInSelection.size.width), currentInternalSize.height + (touchBounds.size.height - _previousTouchBoundsInSelection.size.height));
            CGFloat newAspectRatio = (newInternalSize.width * newInternalSize.height) ? newInternalSize.width / newInternalSize.height : 1;
            CGFloat newBoundsDiagonal = sqrt(pow(newInternalSize.width, 2) + pow(newInternalSize.height, 2));
            CGPoint newCenter = CGPointMake(selectionKeyframe.center.x + CGRectGetMidX(touchBounds) - CGRectGetMidX(_previousTouchBoundsInSelection), selectionKeyframe.center.y + CGRectGetMidY(touchBounds) - CGRectGetMidY(_previousTouchBoundsInSelection));
            
            selectionKeyframe.center = newCenter;
            
            _currentObjectMoveTransaction.action = ^(id target) {
                [singleSelection.keyframeStore storeKeyframe:selectionKeyframe];
                singleSelection.boundsDiagonal = newBoundsDiagonal;
                if ([singleSelection respondsToSelector:@selector(setAspectRatio:)]) {
                    [(id)singleSelection setAspectRatio:newAspectRatio];
                }
            };
            
            [self.singleSelection renderToView:view context:[self createRenderContext]];
            _previousTouchBoundsInSelection = [self boundingRectForTouchesUsingCoordinateSpaceOfView:view];
        }
    }
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
    
    // TODO: roll back transaction?
    _currentObjectMoveTransaction.finalized = YES;
    _currentObjectMoveTransaction = nil;
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

#pragma mark Geometry

- (NSArray<CMDrawable*> *)allHitsAtPoint:(CGPoint)pos {
    return [self.canvasView hitsAtPoint:pos withCanvas:self.canvas];
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

- (CMDrawable *)doHitTest:(CGPoint)pos {
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
    __weak CanvasEditor *weakSelf = self;
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

- (void)insertDrawableAtCurrentTime:(CMDrawable *)drawable {
    CMDrawableKeyframe *keyframe = [drawable.keyframeStore createKeyframeAtTimeIfNeeded:self.time];
    keyframe.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    
    [self.transactionStack doTransaction:[[CMTransaction alloc] initWithTarget:self action:^(id target) {
        [[[target canvas] contents] addObject:drawable];
    } undo:^(id target) {
        [[[target canvas] contents] removeObject:drawable];
    }]];
    
}

- (void)createGroup:(id)sender {
    NSArray<__kindof CMDrawable*> *selection = self.selectedItems.allObjects;
    
    
    /*selection = [selection sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
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
    }*/
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
    for (CMDrawable *d in self.selectedItems) {
        [self deleteDrawable:d]; // TODO: group as one single transaction
    }
}

- (void)deleteDrawable:(CMDrawable *)d {
    NSInteger index = [self.canvas.contents indexOfObject:d];
    [self.transactionStack doTransaction:[[CMTransaction alloc] initWithTarget:self action:^(id target) {
        [[target canvas].contents removeObject:d];
    } undo:^(id target) {
        [[target canvas].contents insertObject:d atIndex:index];
    }]];
}

- (void)duplicateDrawable:(CMDrawable *)d {
    CMDrawable *copy = [d copy];
    [self.transactionStack doTransaction:[[CMTransaction alloc] initWithTarget:self action:^(id target) {
        [[target canvas].contents addObject:copy];
    } undo:^(id target) {
        [[target canvas].contents removeObject:copy];
    }]];
}

- (void)deleteCurrentKeyframeForDrawable:(CMDrawable *)d {
    [d.keyframeStore removeKeyframeAtTime:self.time];
}

#pragma mark Time

- (FrameTime *)duration {
    FrameTime *t = [[FrameTime alloc] initWithFrame:0 atFPS:1];
    for (CMDrawable *d in self.canvas.contents) {
        t = [[d maxTime] maxWith:t];
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

- (void)setCanvasView:(_CMCanvasView *)canvasView {
    if (canvasView != _canvasView) {
        [_canvasView removeFromSuperview];
        _canvasView = canvasView;
        [self addSubview:canvasView];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.canvasView.frame = self.bounds;
}

#pragma mark Selection
- (NSSet<CMDrawable*> *)selectedItems {
    return _selectedItems ? : [NSSet set];
}

- (void)setSelectedItems:(NSSet<CMDrawable*> *)selectedItems {    
    _selectedItems = selectedItems.copy ? : [NSSet new];
    
    [self.delegate canvasDidChangeSelection:self];
    
    _lastSelection = selectedItems.anyObject;
}

- (void)setMultipleSelectionEnabled:(BOOL)multipleSelectionEnabled {
    _multipleSelectionEnabled = multipleSelectionEnabled;
    if (!multipleSelectionEnabled && self.selectedItems.count > 1) {
        self.selectedItems = [NSSet setWithObject:self.selectedItems.anyObject];
    }
}

- (void)userGesturedToSelectDrawable:(CMDrawable *)d {
    // if (d.transientEDUView) return;
    
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

- (CMDrawable *)singleSelection {
    if (_selectedItems.count == 1) {
        return _selectedItems.anyObject;
    } else {
        return nil;
    }
}

#pragma mark Capture
- (void)setPreparedForStaticScreenshot:(BOOL)preparedForStaticScreenshot {
    _preparedForStaticScreenshot = preparedForStaticScreenshot;
}

#pragma mark Rendering

- (void)setRendering:(BOOL)rendering {
    if (rendering != self.rendering) {
        if (rendering) {
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
            [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        } else {
            [_displayLink invalidate];
            _displayLink = nil;
        }
    }
}

- (BOOL)rendering {
    return !!_displayLink;
}

- (CMRenderContext *)createRenderContext {
    CMRenderContext *ctx = [CMRenderContext new];
    ctx.time = self.time;
    ctx.renderMetaInfo = YES;
    ctx.forStaticScreenshot = self.preparedForStaticScreenshot;
    ctx.useFrameTimeForStaticAnimations = self.useTimeForStaticAnimations;
    return ctx;
}

- (void)render {
    self.canvasView = (id)[self.canvas renderToView:self.canvasView context:[self createRenderContext]];
}

@end
