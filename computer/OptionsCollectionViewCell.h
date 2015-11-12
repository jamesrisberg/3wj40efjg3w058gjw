//
//  OptionsCollectionViewCell.h
//  computer
//
//  Created by Nate Parrott on 11/11/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OptionsCell;

@interface OptionsCollectionViewCell : UICollectionViewCell

@property (nonatomic) OptionsCell *cell;
@property (nonatomic) NSString *title;

@end
