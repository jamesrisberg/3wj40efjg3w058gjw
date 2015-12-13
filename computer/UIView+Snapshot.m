//
//  UIView+Snapshot.m
//  computer
//
//  Created by Nate Parrott on 12/13/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "UIView+Snapshot.h"

@implementation UIView (Snapshot)

- (UIImage *)snapshotAtSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [self drawViewHierarchyInRect:CGRectMake(0, 0, size.width, size.height) afterScreenUpdates:NO];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snap;
}

- (UIImage *)snapshotWithMaxDimension:(CGFloat)maxDimension {
    CGFloat scale = MIN(1, MIN(maxDimension / self.bounds.size.width, maxDimension / self.bounds.size.height));
    return [self snapshotAtSize:CGSizeMake(round(self.bounds.size.width * scale), round(self.bounds.size.height * scale))];
}

@end
