//
//  QNHTTPDataController.h
//  QuaNode
//
//  Created by Ahmed Ragab on 1/19/16.
//  Copyright © 2016 quanode.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QNDataController.h"
#import "QNHTTPDataOperation.h"

@interface QNHTTPDataController : QNDataController<QNHTTPDataOperation *> 

@property (nonatomic, copy) NSString *baseURL;

+ (QNHTTPDataController *)sharedController;

@end
