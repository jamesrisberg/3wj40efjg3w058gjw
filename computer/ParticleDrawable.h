//
//  ParticleDrawable.h
//  computer
//
//  Created by Nate Parrott on 11/18/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"

typedef NS_ENUM(NSInteger, ParticleSystemPreset) {
    ParticleSystemPresetFire,
    ParticleSystemPresetSparkle,
    ParticleSystemPresetSmoke,
    ParticleSystemPresetConfetti,
    ParticleSystemPresetSnow
};

@interface ParticleDrawable : Drawable

@property (nonatomic) ParticleSystemPreset preset;

@end
