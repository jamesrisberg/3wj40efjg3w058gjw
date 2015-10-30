//
//  ReplicatorView.m
//  computer
//
//  Created by Nate Parrott on 10/30/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ReplicatorView.h"

@implementation ReplicatorView

+ (Class)layerClass {
    return [CAReplicatorLayer class];
}

- (CAReplicatorLayer *)replicatorLayer {
    return (id)self.layer;
}

@end
