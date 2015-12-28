//
//  CMPhotoPicker.h
//  computer
//
//  Created by Nate Parrott on 12/10/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

@import UIKit;

@interface CMPhotoPicker : UIViewController

+ (id)photoPicker;

@property (nonatomic) NSArray<UIImage*> *viewSnapshots;
@property (nonatomic,copy) void (^imageCallback)(UIImage *image);

- (void)present;

@end
