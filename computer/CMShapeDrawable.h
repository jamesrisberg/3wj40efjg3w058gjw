//
//  CMShapeDrawable.h
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDrawable.h"

@interface CMShapeDrawable : CMDrawable

@property (nonatomic) UIBezierPath *path;
@property (nonatomic) UIColor *fillColor, *strokeColor;
@property (nonatomic) CGFloat strokeWidth;

@end
