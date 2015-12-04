//
//  CMStarDrawable.m
//  computer
//
//  Created by Nate Parrott on 12/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMStarDrawable.h"
#import "CGPointExtras.h"

@implementation CMStarDrawable

- (instancetype)init {
    self = [super init];
    self.numberOfPoints = 5;
    self.valley = 0.5;
    return self;
}

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObjectsFromArray:@[@"valley", @"numberOfPoints"]];
}

- (void)setValley:(CGFloat)valley {
    _valley = valley;
    [self generatePath];
}

- (void)setNumberOfPoints:(NSInteger)numberOfPoints {
    _numberOfPoints = numberOfPoints;
    [self generatePath];
}

- (void)generatePath {
    CGFloat w = 1;
    CGFloat h = 1;
    CGFloat radius = sqrt(pow(w, 2) + pow(h, 2))/2;
    CGPoint center = CGPointMake(w/2, h/2);
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (NSInteger i=0; i<_numberOfPoints; i++) {
        CGFloat startAngle = M_PI * 2 * i / (double)_numberOfPoints - M_PI/2;
        CGFloat stopAngle = M_PI * 2 * (i+1) / (double)_numberOfPoints - M_PI/2;
        CGPoint p1 = CGPointShift(center, startAngle, radius);
        CGPoint p2 = CGPointShift(center, (startAngle + stopAngle)/2, radius * _valley);
        CGPoint p3 = CGPointShift(center, stopAngle, radius);
        if (i == 0) {
            [path moveToPoint:p1];
        } else {
            [path addLineToPoint:p1];
        }
        [path addLineToPoint:p2];
        if (i == _numberOfPoints - 1) {
            [path closePath];
        } else {
            [path addLineToPoint:p3];
        }
    }
    self.path = path;
}

- (NSArray<PropertyModel*>*)uniqueObjectPropertiesWithEditor:(CanvasEditor *)editor {
    PropertyModel *points = [PropertyModel new];
    points.valueMin = 3;
    points.valueMax = 30;
    points.key = @"numberOfPoints";
    points.title = NSLocalizedString(@"Number of points", @"");
    
    PropertyModel *valley = [PropertyModel new];
    valley.valueMax = 1;
    valley.key = @"valley";
    valley.title = NSLocalizedString(@"Valley", @"");
    
    return [[super uniqueObjectPropertiesWithEditor:editor] arrayByAddingObjectsFromArray:@[points, valley]];
}

@end
