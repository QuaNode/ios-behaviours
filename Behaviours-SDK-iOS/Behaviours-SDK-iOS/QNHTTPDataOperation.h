//
//  QNHTTPDataOperation.h
//  QuaNode
//
//  Created by Ahmed Ragab on 1/19/16.
//  Copyright © 2016 quanode.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QNDataOperation.h"

@interface QNHTTPDataOperation : QNDataOperation

@property (nonatomic, strong) NSDictionary *query;
@property (nonatomic, strong) NSDictionary *body;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSString* method;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSDictionary *response;

@end
