//
//  CMCanvas.m
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMCanvas.h"
#import "ConvenienceCategories.h"

@interface _CMCanvasView : CMDrawableView

@property (nonatomic) NSMutableDictionary<NSString*,CMDrawableView*> *viewsByKey;

@end

@implementation _CMCanvasView

- (instancetype)init {
    self = [super init];
    self.viewsByKey = [NSMutableDictionary new];
    return self;
}

@end



@implementation CMCanvas

- (instancetype)initWithKey:(NSString *)key {
    self = [super initWithKey:key];
    self.contents = [NSMutableArray new];
    return self;
}

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObjectsFromArray:@[@"contents"]];
}

- (CMDrawableView *)renderToView:(CMDrawableView *)existingOrNil atTime:(FrameTime *)time {
    _CMCanvasView *v = [existingOrNil isKindOfClass:[_CMCanvasView class]] ? (id)existingOrNil : [_CMCanvasView new];
    
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
        CMDrawableView *newView = [drawable renderToView:existing atTime:time];
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
