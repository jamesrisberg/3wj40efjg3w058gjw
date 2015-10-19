//
//  PhotoDrawable.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "PhotoDrawable.h"
#import "computer-Swift.h"
#import "FilterViewController.h"

@interface PhotoDrawable () <UIImagePickerControllerDelegate>

@property (nonatomic) UIImageView *imageView;

@end

@implementation PhotoDrawable

- (instancetype)init {
    self = [super init];
    
    return self;
}

- (void)primaryEditAction {
    // TODO: show an action sheet
    [self promptToPickPhotoWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (image) {
        [self setImage:image];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)setImage:(UIImage *)image {
    CGFloat oldAspectRatio = self.imageView.image.size.width / self.imageView.image.size.height;
    CGFloat aspectRatio = image.size.width / image.size.height;
    CGSize size = self.bounds.size;
    if (aspectRatio > oldAspectRatio) {
        // we're wider, so shorten the height:
        size.height = size.width / aspectRatio;
    } else {
        // we're thinner, so shorten the width:
        size.width = size.height * aspectRatio;
    }
    self.imageView.image = image;
    self.bounds = CGRectMake(0, 0, size.width, size.height);
    
    if (self.onShapeUpdate) self.onShapeUpdate();
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)setup {
    [super setup];
    self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PlaceholderImage"]];
    [self addSubview:self.imageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}

- (void)promptToPickPhotoWithSource:(UIImagePickerControllerSourceType)source {
    UIImagePickerController *pickerVC = [[UIImagePickerController alloc] init];
    pickerVC.delegate = (id)self;
    // pickerVC.allowsEditing = YES;
    pickerVC.sourceType = source;
    [[self vcForPresentingModals] presentViewController:pickerVC animated:YES completion:nil];
}

- (NSArray <__kindof QuickCollectionItem*> *)optionsItems {
    __weak PhotoDrawable *weakSelf = self;
    QuickCollectionItem *cutOut = [QuickCollectionItem new];
    cutOut.label = @"Cut out…";
    cutOut.action = ^{
        [weakSelf cutOut];
    };
    QuickCollectionItem *filter = [QuickCollectionItem new];
    filter.label = @"Filter…";
    filter.action = ^{
        [weakSelf addFilter];
    };
    return [[super optionsItems] arrayByAddingObjectsFromArray:@[cutOut, filter]];
}

- (void)addFilter {
    UIImage *image = [self.imageView.image resizedWithMaxDimension:1400];
    FilterViewController *filterVC = [[FilterViewController alloc] initWithImage:image callback:^(UIImage *filtered) {
        [self setImage:filtered];
    }];
    [self.vcForPresentingModals presentViewController:filterVC animated:YES completion:nil];
}

- (void)cutOut {
    StickerExtractViewController *extractVC = (id)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"StickerExtractVC"];
    extractVC.onExtractedSticker = ^(UIImage *sticker) {
        if (sticker) {
            [self setImage:sticker];
        }
    };
    extractVC.imageToExtractFrom = self.imageView.image;
    [[self vcForPresentingModals] presentViewController:extractVC animated:YES completion:nil];
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    NSData *imageData = UIImagePNGRepresentation(self.imageView.image);
    [aCoder encodeObject:imageData forKey:@"imageData"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    NSData *imageData = [aDecoder decodeObjectForKey:@"imageData"];
    self.imageView.image = [UIImage imageWithData:imageData];
    return self;
}

@end
