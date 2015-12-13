//
//  UIView+Snapshot.h
//  computer
//
//  Created by Nate Parrott on 12/13/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Snapshot)

- (UIImage *)snapshotAtSize:(CGSize)size;
- (UIImage *)snapshotWithMaxDimension:(CGFloat)maxDimension;

@end
