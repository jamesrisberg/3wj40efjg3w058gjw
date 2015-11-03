//
//  StarDrawable.m
//  computer
//
//  Created by Nate Parrott on 11/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "StarDrawable.h"
#import "CGPointExtras.h"
#import "SliderTableViewCell.h"

@implementation StarDrawable

- (instancetype)init {
    self = [super init];
    _numberOfPoints = 5;
    _valley = 0.5;
    self.bounds = CGRectMake(0, 0, 200, 200);
    [self generatePath];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    _numberOfPoints = [aDecoder decodeIntegerForKey:@"numberOfPoints"];
    _valley = [aDecoder decodeFloatForKey:@"valley"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeInteger:self.numberOfPoints forKey:@"numberOfPoints"];
    [aCoder encodeFloat:self.valley forKey:@"valley"];
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
    CGFloat radius = sqrt(pow(self.bounds.size.width, 2) + pow(self.bounds.size.height, 2))/2;
    CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (NSInteger i=0; i<_numberOfPoints; i++) {
        CGFloat startAngle = M_PI * 2 * i / (double)_numberOfPoints;
        CGFloat stopAngle = M_PI * 2 * (i+1) / (double)_numberOfPoints;
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
    [self setPathPreservingSize:path];
}

- (NSArray<__kindof OptionsViewCellModel*>*)optionsViewCellModels {
    __weak StarDrawable *weakSelf = self;
    NSMutableArray *items = [[super optionsViewCellModels] mutableCopy];
    
    OptionsViewCellModel *numberOfPoints = [OptionsViewCellModel new];
    numberOfPoints.title = NSLocalizedString(@"Number of points", @"");
    numberOfPoints.cellClass = [SliderTableViewCell class];
    numberOfPoints.onCreate = ^(OptionsTableViewCell *cell) {
        __weak SliderTableViewCell *slider = (id)cell;
        [slider setRampedValue:weakSelf.numberOfPoints withMin:2 max:30];
        slider.onValueChange = ^(CGFloat val) {
            weakSelf.numberOfPoints = round([slider getRampedValueWithMin:2 max:30]);
        };
    };
    [items addObject:numberOfPoints];
    
    OptionsViewCellModel *valley = [OptionsViewCellModel new];
    valley.title = NSLocalizedString(@"Valley", @"");
    valley.cellClass = [SliderTableViewCell class];
    valley.onCreate = ^(OptionsTableViewCell *cell) {
        __weak SliderTableViewCell *slider = (id)cell;
        slider.value = weakSelf.valley;
        slider.onValueChange = ^(CGFloat val) {
            weakSelf.valley = val;
        };
    };
    [items addObject:valley];
    
    return items;
}

@end
