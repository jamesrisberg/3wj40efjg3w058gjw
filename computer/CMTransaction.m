//
//  CMTransaction.m
//  computer
//
//  Created by Nate Parrott on 11/30/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMTransaction.h"

static NSString * const CMTransactionStackDidExecuteTransactionNotification = @"CMTransactionStackDidExecuteTransactionNotification";

@interface CMTransaction ()

@property (nonatomic,weak) CMTransactionStack *stack;

@end

@implementation CMTransaction

- (instancetype)initNonFinalizedWithTarget:(id)target action:(CMTransactionBlock)action undo:(CMTransactionBlock)inverse {
    self = [super init];
    _target = target;
    _action = action;
    _inverse = inverse;
    return self;
}

- (instancetype)initWithTarget:(id)target action:(CMTransactionBlock)action undo:(CMTransactionBlock)inverse {
    self = [self initNonFinalizedWithTarget:target action:action undo:inverse];
    self.finalized = YES;
    return self;
}

- (void)setAction:(CMTransactionBlock)action {
    _action = action;
    [self.stack _transactionDidUpdate:self];
}

@end


@interface CMTransactionStack ()

@property (nonatomic) NSMutableArray *redoStack, *undoStack;
@property (nonatomic) BOOL canUndo, canRedo;

@end

@implementation CMTransactionStack

- (void)doTransaction:(CMTransaction *)transaction {
    transaction.stack = self;
    
    if (transaction.inverse) {
        if (!self.undoStack) {
            self.undoStack = [NSMutableArray new];
        }
        [self.undoStack addObject:transaction];
        self.canUndo = YES;
        
        [self.redoStack removeAllObjects];
        self.canRedo = NO;
    }
    transaction.action(transaction.target);
    [[NSNotificationCenter defaultCenter] postNotificationName:CMTransactionStackDidExecuteTransactionNotification object:self];
}

- (void)_transactionDidUpdate:(CMTransaction *)t {
    [[NSNotificationCenter defaultCenter] postNotificationName:CMTransactionStackDidExecuteTransactionNotification object:self];
    t.action(t.target);
}

- (NSInteger)maxStackDepth {
    return 10;
}

- (void)undo {
    CMTransaction *t = self.undoStack.lastObject;
    [self.undoStack removeLastObject];
    t.inverse(t.target);
    self.canUndo = self.undoStack.count > 0;
    
    [self.redoStack addObject:t];
    while (self.redoStack.count > [self maxStackDepth]) {
        [self.redoStack removeObjectAtIndex:0];
    }
    self.canRedo = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:CMTransactionStackDidExecuteTransactionNotification object:self];
}

- (void)redo {
    CMTransaction *t = self.redoStack.lastObject;
    [self.redoStack removeLastObject];
    t.action(t.target);
    self.canRedo = self.redoStack.count > 0;
    
    [self.undoStack addObject:t];
    while (self.undoStack.count > [self maxStackDepth]) {
        [self.undoStack removeObjectAtIndex:0];
    }
    self.canUndo = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:CMTransactionStackDidExecuteTransactionNotification object:self];
}

@end
