//
//  InlineViewControllerCollectionViewCell.h
//  computer
//
//  Created by Nate Parrott on 11/11/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InlineViewControllerCollectionViewCell : UICollectionViewCell

- (void)setViewController:(UIViewController *)vc parentViewController:(UIViewController *)parent;

@end
