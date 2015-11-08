//
//  GifOptimizer.h
//  computer
//
//  Created by Nate Parrott on 11/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GifOptimizer : NSObject

+ (void)optimizeGifAtPath:(NSString *)path doneBlock:(void(^)())doneBlock;

@end
