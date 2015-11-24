//
//  CMMediaStore.h
//  computer
//
//  Created by Nate Parrott on 11/23/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMMediaID;

@interface CMMediaStore : NSObject

+ (CMMediaStore *)shared;
- (CMMediaID *)storeMediaAtURL:(NSURL *)url;
- (void)resizeAndStoreMediaAtURL:(NSURL *)url callback:(void(^)(CMMediaID *mediaID))callback;

@end

@interface CMMediaID : NSObject <NSCoding>

- (void)dispose;
- (CMMediaID *)newReference;
- (NSURL *)url;

@end
