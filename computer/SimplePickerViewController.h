//
//  SimplePickerViewController.h
//  computer
//
//  Created by Nate Parrott on 11/20/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SimplePickerModel : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) id userInfo;

@end

@interface SimplePickerViewController : UIViewController

+ (SimplePickerViewController *)picker;
@property (nonatomic) NSArray<__kindof SimplePickerModel*> *models;
@property (nonatomic) SimplePickerModel *selectedModel;
- (void)presentWithCallback:(void(^)(SimplePickerModel *modelOrNil))callback;
@property (nonatomic) NSString *prompt;

@end
