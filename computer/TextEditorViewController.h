//
//  TextEditorViewController.h
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextEditorViewController : UIViewController

@property (nonatomic) NSAttributedString *text;
@property (nonatomic,copy) void (^textChanged)(NSAttributedString *text);

@end
