//
//  CMParticleDrawable.h
//  computer
//
//  Created by Nate Parrott on 12/4/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDrawable.h"

typedef NS_ENUM(NSInteger, ParticlePreset) {
    ParticlePresetFire = 1,
    ParticlePresetSnow = 2,
    ParticlePresetSparkle = 3,
    ParticlePresetMacaroni = 4,
    ParticlePresetSmoke = 5,
    ParticlePresetOrbs = 6,
    ParticlePresetCustom = 7
};

@interface CMParticleDrawable : CMDrawable

@property (nonatomic) ParticlePreset particlePreset;
@property (nonatomic) NSArray<UIImage*> *customParticleImages;

@end
