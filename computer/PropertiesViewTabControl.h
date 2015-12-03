//
//  PropertiesViewTabControl.h
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PropertiesViewTabControl : UIScrollView

@property (nonatomic) NSArray<NSString*> *tabTitles;
@property (nonatomic) NSInteger highlightedTabIndex;
@property (nonatomic,copy) void (^onTabSelected)(NSInteger index);

@end
