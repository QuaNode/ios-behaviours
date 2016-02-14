//
//  QNDataController.h
//  QuaNode
//
//  Created by Ahmed Ragab on 1/19/16.
//  Copyright © 2016 quanode.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QNDataOperation.h"

@interface QNDataController <Operation : QNDataOperation *>: NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

- (void)executeOperation:(Operation)operation withCompletion:(void(^)(Operation))completion;
- (void)executeOperation:(Operation)operation;

@end
