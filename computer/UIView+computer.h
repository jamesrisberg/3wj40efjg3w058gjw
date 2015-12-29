//
//  UIView+computer.h
//  computer
//
//  Created by Nate Parrott on 9/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (computer)

- (void)replaceWith:(UIView *)replacement;
- (BOOL)viewHasAncestor:(UIView *)parent;

@end
