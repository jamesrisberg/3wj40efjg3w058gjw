//
//  CMCanvas.h
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMDrawable.h"

@interface CMCanvas : NSObject

@property (nonatomic) NSMutableArray<__kindof CMDrawable*> *drawables;

@end
