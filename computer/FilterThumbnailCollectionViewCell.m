//
//  FilterThumbnailCollectionViewCell.m
//  computer
//
//  Created by Nate Parrott on 11/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FilterThumbnailCollectionViewCell.h"

@interface FilterThumbnailCollectionViewCell ()

@property (nonatomic) UIImageView *imageView;

@end

@implementation FilterThumbnailCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.layer.borderWidth = 2;
    self.layer.cornerRadius = 3;
    self.clipsToBounds = YES;
    self.imageView = [UIImageView new];
    [self.contentView addSubview:self.imageView];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.frame = self.contentView.bounds;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.layer.borderColor = selected ? [UIColor colorWithWhite:0.7 alpha:1].CGColor : nil;
}

- (void)setFilter:(GPUImageFilter *)filter {
    _filter = filter;
    [self process];
}

- (void)setInput:(UIImage *)input {
    _input = input;
    [self process];
}

- (void)process {
    UIImage *pic = self.input;
    GPUImageFilter *filter = self.filter;
    if (pic && filter) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *result = [filter imageByFilteringImage:pic];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (pic == self.input && filter == self.filter) {
                    self.imageView.image = result;
                }
            });
        });
    }
}

@end
