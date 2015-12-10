//
//  FilterThumbnailCollectionViewCell.h
//  computer
//
//  Created by Nate Parrott on 11/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GPUImage.h>

@interface FilterThumbnailCollectionViewCell : UICollectionViewCell

// these two are mutually exclusive:
@property (nonatomic) GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic) UIImage *customImage;

@property (nonatomic) UIImage *input;

@end
