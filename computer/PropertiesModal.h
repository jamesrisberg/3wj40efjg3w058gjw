//
//  PropertiesModal.h
//  computer
//
//  Created by Nate Parrott on 11/11/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuickCollectionModal.h"
#import "OptionsView.h"

@interface PropertiesModal : UIViewController

@property (nonatomic) NSArray<__kindof QuickCollectionItem*> *items;
@property (nonatomic) NSArray<__kindof OptionsViewCellModel*> *optionsCellModels;
@property (nonatomic) UIViewController *inlineViewController;
@property (nonatomic) QuickCollectionItem *mainAction;

@end
