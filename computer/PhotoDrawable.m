//
//  PhotoDrawable.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "PhotoDrawable.h"

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
    [picker dismissViewControllerAnimated:YES completion:nil];
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

@end
