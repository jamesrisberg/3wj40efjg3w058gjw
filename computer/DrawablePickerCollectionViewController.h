//
//  DrawablePickerCollectionViewController.h
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CMDrawable;

@interface DrawablePickerCollectionViewController : UICollectionViewController

- (instancetype)initWithDrawables:(NSArray<CMDrawable*>*)drawables snapshotViews:(NSArray<UIView*>*)snapshots callback:(void(^)(CMDrawable *drawableOrNil))callback;

@end
