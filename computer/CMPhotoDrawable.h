//
//  CMPhotoDrawable.h
//  computer
//
//  Created by Nate Parrott on 12/1/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDrawable.h"
@class CMTransactionStack;

@interface CMPhotoDrawable : CMDrawable

@property (nonatomic) UIImage *image;
@property (nonatomic) CGFloat aspectRatio;
- (void)setImage:(UIImage *)image withTransactionStack:(CMTransactionStack *)stack;
- (void)promptToPickPhotoFromImageSearchWithTransactionStack:(CMTransactionStack *)transactionStack;

@end
