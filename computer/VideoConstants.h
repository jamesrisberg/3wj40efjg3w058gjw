//
//  VideoConstants.h
//  computer
//
//  Created by Nate Parrott on 10/30/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#ifndef VideoConstants_h
#define VideoConstants_h

#define VC_FPS 32
#define VC_GIF_FPS 16
#define VC_TIMELINE_CELLS_PER_SECOND 2

// all static animations should have a period of VC_LONGEST_STATIC_ANIMATION_PERIOD / (2^n), where n is an integer
#define VC_LONGEST_STATIC_ANIMATION_PERIOD 2.0 // seconds

#endif /* VideoConstants_h */
