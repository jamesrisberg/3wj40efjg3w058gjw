//
//  CMShapeDrawable.m
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMShapeDrawable.h"

@interface _CMShapeView : CMDrawableView

@end

@implementation _CMShapeView

+ (Class)layerClass {
    return [CAShapeLayer class];
}

@end

@implementation CMShapeDrawable

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObjectsFromArray:@[@"lineWidth", @"strokeColor", @"fillColor", @"path"]];
}

- (UIView *)renderToView:(UIView *)existingOrNil atTime:(FrameTime *)time {
    _CMShapeView *shapeView = [existingOrNil isKindOfClass:[_CMShapeView class]] ? (id)existingOrNil : [_CMShapeView new];
    CAShapeLayer *shapeLayer = (id)shapeView.layer;
    shapeLayer.fillColor = self.fillColor.CGColor;
    shapeLayer.strokeColor = self.strokeColor.CGColor;
    shapeLayer.lineWidth = self.strokeWidth;
    shapeLayer.path = self.path.CGPath;
    [super renderToView:shapeView atTime:time];
    return shapeView;
}

@end
