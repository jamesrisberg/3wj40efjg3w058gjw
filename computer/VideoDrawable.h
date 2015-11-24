//
//  VideoDrawable.h
//  computer
//
//  Created by Nate Parrott on 11/24/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"
#import "CMMediaStore.h"

@interface VideoDrawable : Drawable

@property (nonatomic) CMMediaID *media;
@property (nonatomic,readonly) FrameTime *videoDuration;

@end
