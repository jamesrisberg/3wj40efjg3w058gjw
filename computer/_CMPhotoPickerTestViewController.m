//
//  _CMPhotoPickerTestViewController.m
//  computer
//
//  Created by Nate Parrott on 12/10/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "_CMPhotoPickerTestViewController.h"
#import "CMPhotoPicker.h"
#import "ConvenienceCategories.h"

@interface _CMPhotoPickerTestViewController ()

@property (nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) IBOutlet UIView *v1, *v2, *v3;

@end

@implementation _CMPhotoPickerTestViewController

- (IBAction)pick:(id)sender {
    CMPhotoPicker *picker = [CMPhotoPicker photoPicker];
    
    NSArray *views = @[self.v1, self.v2, self.v3];
    /*picker.snapshotViews = [views map:^id(id obj) {
        return [obj snapshotViewAfterScreenUpdates:NO];
    }];*/
    picker.imageCallback = ^(UIImage *image) {
        self.imageView.image = image;
    };
    [picker present];
}

@end
