//
//  EditorViewController+InsertMedia.m
//  computer
//
//  Created by Nate Parrott on 11/24/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EditorViewController+InsertMedia.h"
#import "PhotoDrawable.h"
#import "CMMediaStore.h"
#import "VideoDrawable.h"
@import MobileCoreServices;
@import AssetsLibrary;

@implementation EditorViewController (InsertMedia)

- (void)insertMediaWithSource:(UIImagePickerControllerSourceType)source mediaTypes:(NSArray *)mediaTypes {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = source;
    picker.mediaTypes = mediaTypes;
    picker.allowsEditing = YES;
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
        VideoDrawable *d = [VideoDrawable new];
        d.frame = CGRectMake(0, 0, 250, 250);
        d.media = mediaID;
        [self.canvas insertDrawable:d];
    }];
}

- (void)insertImage:(UIImage *)image {
    PhotoDrawable *d = [PhotoDrawable new];
    d.bounds = CGRectMake(0, 0, 250, 250);
    [d setImage:image];
    [self.canvas insertDrawable:d];
}

@end
