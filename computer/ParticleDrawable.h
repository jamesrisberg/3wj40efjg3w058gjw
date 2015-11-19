//
//  ParticleDrawable.h
//  computer
//
//  Created by Nate Parrott on 11/18/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"

typedef NS_ENUM(NSInteger, ParticleAppearancePreset) {
    ParticleAppearancePresetFire,
    ParticleAppearancePresetSnow,
    ParticleAppearancePresetSparkle,
    ParticleAppearancePresetMacaroni
};

typedef NS_ENUM(NSInteger, ParticleMotionPreset) {
    ParticleMotionPresetFire,
    ParticleMotionPresetSnow,
    ParticleMotionPresetSparkle
};

@interface ParticleDrawable : Drawable

- (void)setAppearance:(ParticleAppearancePreset)appearance motion:(ParticleMotionPreset)motion;

@end
