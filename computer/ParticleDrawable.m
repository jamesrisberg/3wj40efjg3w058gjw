//
//  ParticleDrawable.m
//  computer
//
//  Created by Nate Parrott on 11/18/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ParticleDrawable.h"

@interface ParticleDrawable ()

@property (nonatomic) CAEmitterLayer *emitter;
@property (nonatomic,copy) void(^onUpdateParticleLayout)(CGSize size, CAEmitterLayer *emitter);

@end

@implementation ParticleDrawable

- (void)setup {
    [super setup];
    self.preset = ParticleSystemPresetSparkle;
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

- (void)setPreset:(ParticleSystemPreset)preset {
    _preset = preset;
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.emitterShape = kCAEmitterLayerRectangle;
    self.emitter = emitter;
    
    if (preset == ParticleSystemPresetFire) {
        [self updateAspectRatio:2];
        [self fire];
    } else if (preset == ParticleSystemPresetSparkle) {
        [self updateAspectRatio:1];
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
    cell.scale = 1.5;
    cell.scaleRange = 0.5;
    cell.scaleSpeed = -1.5;
    cell.color = [UIColor colorWithRed:0.505 green:0.230 blue:0.073 alpha:1].CGColor;
    cell.lifetime = 1.7;
    cell.emissionLongitude = -M_PI/2;
    cell.emissionRange = M_PI/20;
    cell.velocity = 130;
    cell.velocityRange = 50;
    cell.alphaRange = 0.2;
    cell.alphaSpeed = -0.6;
    cell.birthRate = 100;
    self.emitter.emitterCells = @[cell];
    self.emitter.renderMode = kCAEmitterLayerAdditive;
    
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height * 0.7);
        layer.emitterSize = CGSizeMake(size.width * 0.7, size.height * 0.2);
    };
}

- (void)sparkle {
    CAEmitterCell *cell1 = [CAEmitterCell emitterCell];
    cell1.contents = (id)[[UIImage imageNamed:@"sparkle"] CGImage];
    
    CAEmitterCell *cell2 = [CAEmitterCell emitterCell];
    cell2.contents = (id)[[UIImage imageNamed:@"sparkle"] CGImage];
    
    NSArray *cells = @[cell1, cell2];
    
    for (CAEmitterCell *cell in cells) {
        cell.scale = 0;
        cell.scaleRange = 0;
        cell.scaleSpeed = 0.3;
        cell.lifetime = 2;
        cell.spin = M_PI * 2 * 0.1;
        cell.spinRange = M_PI * 2 * 0.1;
        cell.alphaRange = 0.2;
        cell.alphaSpeed = -0.5;
        cell.birthRate = 4;
    }
    
    self.emitter.emitterCells = cells;
    
    self.onUpdateParticleLayout = ^(CGSize size, CAEmitterLayer *layer) {
        layer.emitterPosition = CGPointMake(size.width/2, size.height/2);
        layer.emitterSize = CGSizeMake(size.width * 1.1, size.height * 1.1);
    };
}

@end
