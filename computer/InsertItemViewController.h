//
//  InsertItemViewController.h
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EditorViewController;

@interface InsertItemViewController : UIViewController

- (void)present;
@property (nonatomic) EditorViewController *editorVC;

@end
