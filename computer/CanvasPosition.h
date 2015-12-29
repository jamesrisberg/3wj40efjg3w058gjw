//
//  CanvasPosition.h
//  computer
//
//  Created by Nate Parrott on 12/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

@import UIKit;

@interface CanvasPosition : NSObject

@property (nonatomic) CGSize screenSpan; // if screenSpan = {100, 100}, fit _at least_ a 100x100 object on screen
@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat rotation;

@end
