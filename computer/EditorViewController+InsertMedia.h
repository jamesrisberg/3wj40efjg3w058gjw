//
//  EditorViewController+InsertMedia.h
//  computer
//
//  Created by Nate Parrott on 11/24/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EditorViewController.h"

@interface EditorViewController (InsertMedia) <UIImagePickerControllerDelegate>

- (void)insertMediaWithSource:(UIImagePickerControllerSourceType)source mediaTypes:(NSArray *)mediaTypes;

@end
