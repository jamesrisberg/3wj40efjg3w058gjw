//
//  EditorViewController+InsertMedia.m
//  computer
//
//  Created by Nate Parrott on 11/24/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EditorViewController+InsertMedia.h"
#import "PhotoDrawable.h"
@import MobileCoreServices;

@implementation EditorViewController (InsertMedia)

- (void)insertMediaWithSource:(UIImagePickerControllerSourceType)source mediaTypes:(NSArray *)mediaTypes {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = source;
    picker.mediaTypes = mediaTypes;
    picker.allowsEditing = YES;
    picker.delegate = (id)self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(id)kUTTypeMovie]) {
        [self insertMovieAtURL:info[UIImagePickerControllerMediaURL]];
    } else if ([mediaType isEqualToString:(id)kUTTypeImage]) {
        UIImage *image = info[UIImagePickerControllerEditedImage] ? : info[UIImagePickerControllerOriginalImage];
        [self insertImage:image];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)insertMovieAtURL:(NSURL *)url {
    
}

- (void)insertImage:(UIImage *)image {
    PhotoDrawable *d = [PhotoDrawable new];
    d.bounds = CGRectMake(0, 0, 250, 250);
    [d setImage:image];
    [self.canvas insertDrawable:d];
}

@end
