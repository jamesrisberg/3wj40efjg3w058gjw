//
//  ParticleDrawable.h
//  computer
//
//  Created by Nate Parrott on 11/18/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"

typedef NS_ENUM(NSInteger, ParticlePreset) {
    ParticlePresetFire,
    ParticlePresetSnow,
    ParticlePresetSparkle,
    ParticlePresetMacaroni
};

@interface ParticleDrawable : Drawable

@property (nonatomic) ParticlePreset particlePreset;

@end
