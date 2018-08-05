//
//  QNHTTPDataController.m
//  QuaNode
//
//  Created by Ahmed Ragab on 1/19/16.
//  Copyright © 2016 quanode.com. All rights reserved.
//

#import "QNHTTPDataController.h"
#import <objc/runtime.h>

@interface NSDictionary (Null_Values)

+ (void)load;
- (id)Null_Values_objectForKeyedSubscript:(id)key;

@end

@implementation NSDictionary (Null_Values)

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class class = [self class];
        SEL originalSelector = @selector(objectForKeyedSubscript:);
        SEL swizzledSelector = @selector(Null_Values_objectForKeyedSubscript:);
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (id)Null_Values_objectForKeyedSubscript:(id)key {
    
    NSString *value = [self Null_Values_objectForKeyedSubscript:key];
    if (![value isKindOfClass:[NSString class]] || ![value.lowercaseString isEqualToString:@"null"]) {
        
        return value;
    }
    return nil;
}

@end

@implementation QNHTTPDataController

static QNHTTPDataController *sharedController;

+ (QNHTTPDataController *)sharedController {
    
    @synchronized(self) {
        
        if (sharedController == nil) {
            
            sharedController = [[super allocWithZone:NULL] init];
        }
    }
    return sharedController;
}

+ (id)allocWithZone:(NSZone *)zone {
    
    return [[self sharedController] self];
}

- (id)copyWithZone:(NSZone *)zone {
    
    return self;
}

- (void)executeOperation:(QNHTTPDataOperation *)operation {
    
    NSMutableString *query = @"".mutableCopy;
    for (NSString *key in operation.query) {
        
        [query appendFormat:@"%@%@=%@",query.length == 0 ? @"?" : @"&", [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], [operation.query[key] isKindOfClass:[NSString class]] ? [operation.query[key] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] : operation.query[key]];
    }
    NSString *url = [NSString stringWithFormat:@"%@%@%@",self.basePath, operation.path,query];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    for (NSString *key in operation.headers) {
        
        [request setValue:operation.headers[key] forHTTPHeaderField:key];
    }
    if (operation.body.count > 0) {
        
        [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        NSError *er = nil;
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:operation.body options:0 error:&er]];
        if (er) {
            
            NSLog(@"%@ %@: %@", [self class], NSStringFromSelector(_cmd), er);
            operation.error = er;
        }
    }
    [request setHTTPMethod:operation.method];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.networkServiceType = NSURLNetworkServiceTypeBackground;
    configuration.allowsCellularAccess = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSCondition *condition = [[NSCondition alloc] init];
    __weak NSCondition *CONDITION = condition;
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error){
        
        if (!error) {
            
            if (data.length > 0) {
                
                //NSLog(@"%@", [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding]);
                NSError *err = nil;
                NSMutableDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
                if (err) {
                    
                    NSLog(@"%@ %@: %@", [self class], NSStringFromSelector(_cmd), err);
                    operation.error = err;
                }
                operation.responseBody = responseObject.copy;
                operation.responseHeaders = ((NSHTTPURLResponse *)response).allHeaderFields;
            }
        } else {
            
            operation.error = error;
        }
        [CONDITION signal];
    }];
    [condition lock];
    [task resume];
    [condition wait];
    [condition unlock];
}

@end
