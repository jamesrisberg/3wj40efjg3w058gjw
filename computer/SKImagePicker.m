//
//  SKImagePicker.m
//  Sketch
//
//  Created by Nate Parrott on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SKImagePicker.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface SKImagePicker ()

@end

@implementation SKImagePicker
@synthesize callback=_callback;

-(id)init {
    self = [super initWithNibName:@"SKImagePicker" bundle:nil];
    self.title = @"Image";
    return self;
}
@synthesize imageFill=_imageFill;
-(void)setImageFill:(SKImageFill *)imageFill {
    _imageFill = imageFill;
    [self updateDisplay];
}
-(void)viewDidLoad {
    self.view.backgroundColor = [UIColor whiteColor];
    if (!self.imageFill) {
        self.imageFill = [SKImageFill new];
    }
    _takeImageButton.hidden = ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    [self updateDisplay];
}
-(void)updateDisplay {
    _imageView.image = self.imageFill.image;
    _fillModePicker.selectedSegmentIndex = self.imageFill.fillMode;
}
-(void)imageFillDidUpdate {
    if (self.callback) {
        self.callback(self.imageFill);
    }
    [self updateDisplay];
}
-(IBAction)pickImage:(id)sender {
    UIImagePickerController* picker = [[UIImagePickerController alloc] init
                                       ];
    picker.delegate = self;
    picker.mediaTypes = [NSArray arrayWithObject:(id)kUTTypeImage];
    picker.sourceType = (sender==_selectImageButton)? UIImagePickerControllerSourceTypePhotoLibrary : UIImagePickerControllerSourceTypeCamera;
    picker.allowsEditing = YES;
    [self presentViewController:picker animated:YES completion:nil];
}
-(IBAction)mask:(id)sender {
    // TODO: remove this UI
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage* editedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    self.imageFill.image = editedImage;
    [self imageFillDidUpdate];
    
    [picker dismissViewControllerAnimated:YES completion:nil];

}

-(IBAction)fillModeChanged:(id)sender {
    self.imageFill.fillMode = [_fillModePicker selectedSegmentIndex];
    [self imageFillDidUpdate];
}

@end
