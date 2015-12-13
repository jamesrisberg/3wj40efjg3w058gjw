//
//  CMCanvas.m
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMCanvas.h"
#import "ConvenienceCategories.h"
#import "CGPointExtras.h"

@interface _CMCanvasView ()

@property (nonatomic) NSMutableDictionary<NSString*,CMDrawableView*> *viewsByKey;

@end

@implementation _CMCanvasView


- (instancetype)init {
    self = [super init];
    self.viewsByKey = [NSMutableDictionary new];
    return self;
}

- (NSArray<CMDrawable*> *)hitsAtPoint:(CGPoint)point withCanvas:(CMCanvas *)associatedCanvas {
    const CGFloat centerLeeway = 40; // for small objects
    
    NSMutableArray *hitViews = [NSMutableArray new];
    for (CMDrawableView *view in self.viewsByKey.allValues) {
        // TODO: take into account transforms; don't use UIView's own math
        if ([view pointInside:[view convertPoint:point fromView:self] withEvent:nil]) {
            [hitViews addObject:view];
        } else if (CGPointDistance(point, view.center) < centerLeeway) {
            [hitViews addObject:view];
        }
    }
    
    NSDictionary *viewsByKey = [associatedCanvas.contents mapToDict:^id(__autoreleasing id *key) {
        CMDrawable *drawable = *key;
        *key = drawable.key;
        return drawable;
    }];
    
    NSArray *hitKeys = [hitViews map:^id(id obj) {
        // TOOD speed this up
        for (NSString *key in _viewsByKey) {
            if (_viewsByKey[key] == obj) {
                return key;
            }
        }
        return nil;
    }];
    
    return [hitKeys map:^id(id obj) {
        return viewsByKey[obj];
    }];
}

- (NSArray<CMDrawableView*>*)allDrawableViews {
    return _viewsByKey.allValues;
}

- (NSArray<CMDrawable*> *)allItemsOverlappingDrawable:(CMDrawable *)d withCanvas:(CMCanvas *)associatedCanvas {
    CMDrawableView *v = [self viewForDrawable:d];
    CGRect bbox = v.unrotatedBoundingBox;
    return [associatedCanvas.contents map:^id(id obj) {
        CMDrawableView *v2 = [self viewForDrawable:obj];
        if (CGRectIntersectsRect(v2.unrotatedBoundingBox, bbox)) {
            return obj;
        } else {
            return nil;
        }
    }];
}

- (CMDrawableView *)viewForDrawable:(CMDrawable *)drawable {
    return self.viewsByKey[drawable.key];
}

@end



@implementation CMCanvas

- (instancetype)init {
    self = [super init];
    self.contents = [NSMutableArray new];
    return self;
}

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObjectsFromArray:@[@"contents"]];
}

- (CMDrawableView *)renderToView:(CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx {    
    _CMCanvasView *v = [existingOrNil isKindOfClass:[_CMCanvasView class]] ? (id)existingOrNil : [_CMCanvasView new];
    v.bounds = CGRectMake(0, 0, ctx.canvasSize.width, ctx.canvasSize.height);
    ctx.canvasView = v;
    
    NSArray *keys = [self.contents map:^id(id obj) {
        return [obj key];
    }];
    NSSet *keySet = [NSSet setWithArray:keys];
    for (NSString *oldKey in v.viewsByKey.allKeys) {
        if (![keySet containsObject:oldKey]) {
            [v.viewsByKey[oldKey] removeFromSuperview];
            [v.viewsByKey removeObjectForKey:oldKey];
        }
    }
    
    for (CMDrawable *drawable in self.contents) {
        CMDrawableView *existing = v.viewsByKey[drawable.key];
        CMDrawableView *newView = [drawable renderFullyWrappedWithView:existing context:ctx];
        if (newView == existing) {
            [v bringSubviewToFront:newView];
        } else {
            [existing removeFromSuperview];
            [v addSubview:newView];
        }
        v.viewsByKey[drawable.key] = newView;
    }
    
    return v;
}

@end
