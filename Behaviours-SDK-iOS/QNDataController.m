//
//  QNDataController.m
//  QuaNode
//
//  Created by Ahmed Ragab on 1/19/16.
//  Copyright © 2016 quanode.com. All rights reserved.
//

#import "QNDataController.h"

@implementation QNDataController

@synthesize operationQueue=_operationQueue;

- (NSOperationQueue *)operationQueue {
    
    if (_operationQueue) {
        
        return _operationQueue;
    }
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.maxConcurrentOperationCount = 1;
    return _operationQueue;
}

- (void)executeOperation:(QNDataOperation *)operation withCompletion:(void(^)(QNDataOperation *))completion {
    
    if ([[NSThread currentThread] isMainThread]) {
        
        NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(executeOperation:) object:operation];
        op.completionBlock = ^{
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                if (completion) {
                    
                    completion(operation);
                }
            }];
        };
        [self.operationQueue addOperation:op];
    } else {
        
        [self executeOperation:operation];
        if (completion) {
            
            completion(operation);
        }
    }
}

- (void)executeOperation:(QNDataOperation *)operation { }

@end
