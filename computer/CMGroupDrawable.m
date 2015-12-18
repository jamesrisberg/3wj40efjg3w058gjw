//
//  CMGroupDrawable.m
//  computer
//
//  Created by Nate Parrott on 12/16/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMGroupDrawable.h"

@implementation CMGroupDrawable

- (NSString *)drawableTypeDisplayName {
    return NSLocalizedString(@"Group", @"A group object");
}

- (CGFloat)aspectRatio {
    CGRect contentBounds = [self contentBoundingBox];
    return contentBounds.size.width / contentBounds.size.height;
}

- (id<UICoordinateSpace>)childCoordinateSpace:(CMRenderContext *)ctx {
    CGRect contentBounds = [self contentBoundingBox];
    
    CanvasCoordinateSpace *space = [CanvasCoordinateSpace new];
    space.canvasView = ctx.canvasView;
    space.screenSpan = contentBounds.size.width;
    space.center = CGPointMake(CGRectGetMidX(contentBounds), CGRectGetMidY(contentBounds));
    
    return space;
}

@end
