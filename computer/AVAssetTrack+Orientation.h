//
//  AVAssetTrack+Orientation.h
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
@import ImageIO;

@interface AVAssetTrack (Orientation)

- (CGImagePropertyOrientation)orientation;

@end
