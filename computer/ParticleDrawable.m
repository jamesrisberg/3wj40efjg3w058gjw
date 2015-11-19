//
//  ParticleDrawable.m
//  computer
//
//  Created by Nate Parrott on 11/18/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ParticleDrawable.h"
#import "ConvenienceCategories.h"

@interface ParticleDrawable ()

@property (nonatomic) CAEmitterLayer *emitter;
@property (nonatomic,copy) void(^onUpdateParticleLayout)(CGSize size, CAEmitterLayer *emitter);

@end

@implementation ParticleDrawable

- (void)setup {
    [super setup];
    self.particlePreset = ParticlePresetMacaroni;
}

- (void)setEmitter:(CAEmitterLayer *)emitter {
    [_emitter removeFromSuperlayer];
    _emitter = emitter;
    [self.layer addSublayer:emitter];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.emitter.frame = self.bounds;
    if (self.onUpdateParticleLayout) {
        self.onUpdateParticleLayout(self.bounds.size, self.emitter);
    }
}


- (void)setParticlePreset:(ParticlePreset)particlePreset {
    _particlePreset = particlePreset;
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.emitterShape = kCAEmitterLayerRectangle;
    self.emitter = emitter;
    
    if (particlePreset == ParticlePresetFire) {
        [self fire];
    } else if (particlePreset == ParticlePresetMacaroni) {
        [self macaroni];
    } else if (particlePreset == ParticlePresetSnow) {
        [self snow];
    } else if (particlePreset == ParticlePresetSparkle) {
        [self sparkle];
    }
    
    if (self.onUpdateParticleLayout) {
        self.onUpdateParticleLayout(self.bounds.size, self.emitter);
    }
}

#pragma mark Presets

- (void)fire {
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)[[UIImage imageNamed:@"spark"] CGImage];
    cell.color = [UIColor colorWithRed:0.505 green:0.230 blue:0.073 alpha:1].CGColor;
    cell.alphaRange = 0.2;
    cell.alphaSpeed = -0.6;
    self.emitter.emitterCells = @[cell];
    self.emitter.renderMode = kCAEmitterLayerAdditive;
    
    [self updateAspectRatio:2];
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height * 0.7);
        layer.emitterSize = CGSizeMake(size.width * 0.7, size.height * 0.2);
    };
    for (CAEmitterCell *cell in self.emitter.emitterCells) {
        cell.birthRate = 100.0 / self.emitter.emitterCells.count;
        cell.scale = 1.5;
        cell.scaleRange = 0.5;
        cell.scaleSpeed = -1.3;
        cell.lifetime = 1.7;
        cell.emissionLongitude = -M_PI/2;
        cell.emissionRange = M_PI/20;
        cell.velocity = 130;
        cell.velocityRange = 50;
    }
}

- (void)macaroni {
    NSArray *images = @[@"mac1", @"mac2", @"mac3", @"mac4"];
    self.emitter.emitterCells = [images map:^id(id obj) {
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        cell.contents = (id)[[UIImage imageNamed:obj] CGImage];
        cell.color = [UIColor colorWithWhite:1 alpha:0.1].CGColor;
        cell.alphaRange = 0.1;
        cell.alphaSpeed = 0.6;
        return cell;
    }];
    
    [self updateAspectRatio:3];
    for (CAEmitterCell *cell in self.emitter.emitterCells) {
        cell.scale = 0.3;
        cell.scaleSpeed = -0.1;
        cell.lifetime = 3;
        cell.emissionLongitude = M_PI/2;
        // cell.emissionRange = 2*M_PI * 0.1;
        cell.velocity = 90;
        cell.velocityRange = 60;
        cell.birthRate = 100.0 / self.emitter.emitterCells.count;
        cell.spin = 0;
        cell.spinRange = 0.9;
    }
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height * 0.2);
        layer.emitterSize = CGSizeMake(size.width * 0.9, size.height * 0.2);
    };
}

- (void)snow {
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.contents = (id)[UIImage imageNamed:@"spark"].CGImage;
    cell.color = [UIColor colorWithRed:0.9 green:0.9 blue:0.95 alpha:1].CGColor;
    cell.blueRange = 0.05;
    self.emitter.emitterCells = @[cell];
    
    [self updateAspectRatio:2];
    for (CAEmitterCell *cell in self.emitter.emitterCells) {
        cell.alphaSpeed = -0.34;
        cell.alphaRange = 0.3;
        cell.scale = 0.2;
        cell.scaleRange = 0.1;
        cell.scaleSpeed = -0.02;
        cell.lifetime = 3;
        cell.emissionLongitude = M_PI/2;
        // cell.emissionRange = 2*M_PI * 0.1;
        cell.velocity = 90;
        cell.velocityRange = 60;
        cell.birthRate = 200.0 / self.emitter.emitterCells.count;
    }
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height * 0.2);
        layer.emitterSize = CGSizeMake(size.width * 0.9, size.height * 0.2);
    };
}

- (void)sparkle {
    CAEmitterCell *cell1 = [CAEmitterCell emitterCell];
    cell1.contents = (id)[[UIImage imageNamed:@"sparkle"] CGImage];
    
    CAEmitterCell *cell2 = [CAEmitterCell emitterCell];
    cell2.contents = (id)[[UIImage imageNamed:@"sparkle"] CGImage];
    
    NSArray *cells = @[cell1, cell2];
    self.emitter.emitterCells = cells;
    
    [self updateAspectRatio:1];
    
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height/2);
        layer.emitterSize = CGSizeMake(size.width * 1.1, size.height * 1.1);
    };
    
    for (CAEmitterCell *cell in self.emitter.emitterCells) {
        cell.scale = 0;
        cell.scaleRange = 0;
        cell.scaleSpeed = 0.3;
        cell.lifetime = 2;
        cell.spin = M_PI * 2 * 0.1;
        cell.spinRange = M_PI * 2 * 0.1;
        cell.alphaRange = 0.2;
        cell.alphaSpeed = -0.5;
        cell.birthRate = 10;
    }
}

@end
