//
//  EditorViewController+InsertMedia.m
//  computer
//
//  Created by Nate Parrott on 11/24/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EditorViewController+InsertMedia.h"
#import "CMMediaStore.h"
#import "CMPhotoDrawable.h"
#import "CMVideoDrawable.h"
@import MobileCoreServices;
@import AssetsLibrary;

@implementation EditorViewController (InsertMedia)

- (void)insertMediaWithSource:(UIImagePickerControllerSourceType)source mediaTypes:(NSArray *)mediaTypes {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = source;
    picker.mediaTypes = mediaTypes;
    picker.allowsEditing = NO;
    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
    picker.delegate = (id)self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(id)kUTTypeMovie]) {
        NSURL *url = info[UIImagePickerControllerMediaURL] ? : info[UIImagePickerControllerReferenceURL];
        NSLog(@"URL: %@", url);
        [self insertMovieAtURL:url];
    } else if ([mediaType isEqualToString:(id)kUTTypeImage]) {
        UIImage *image = info[UIImagePickerControllerEditedImage] ? : info[UIImagePickerControllerOriginalImage];
        [self insertImage:image];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)insertMovieAtURL:(NSURL *)url {
    [[CMMediaStore shared] storeMediaAtURL:url callback:^(CMMediaID *mediaID) {
        CMVideoDrawable *v = [CMVideoDrawable new];
        v.boundsDiagonal = 300;
        v.media = mediaID;
        [self.canvas insertDrawableAtCurrentTime:v];
    }];
}

- (void)insertImage:(UIImage *)image {
    CMPhotoDrawable *p = [CMPhotoDrawable new];
    p.boundsDiagonal = 300;
    [p setImage:image withTransactionStack:self.canvas.transactionStack];
    [self.canvas insertDrawableAtCurrentTime:p];
}

@end
