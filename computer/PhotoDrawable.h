//
//  PhotoDrawable.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"

@interface PhotoDrawable : Drawable

- (void)promptToPickPhotoWithSource:(UIImagePickerControllerSourceType)source;
- (void)promptToPickPhotoFromImageSearch;
- (void)setImage:(UIImage *)image;

@end
