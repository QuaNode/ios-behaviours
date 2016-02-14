//
//  Behaviours_SDK_iOS.m
//  Behaviours-SDK-iOS
//
//  Created by Ahmed Ragab on 2/14/16.
//  Copyright © 2016 QuaNode. All rights reserved.
//

#import "QNBehaviours.h"
#import "QNHTTPDataController.h"
#import "QNHTTPDataOperation.h"

static QNBehaviours *sharedBehaviours = nil;

@implementation QNBehaviours

+ (QNBehaviours *)sharedBehaviours:(NSString *)basePath {
    
    @synchronized(self) {
        
        if (sharedBehaviours == nil) {
            
            if ([[NSThread currentThread] isMainThread]) {
                
                @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"you should create behaviours in background thread first time" userInfo:nil];
            }
            if (!basePath) {
                
                @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"you should provide base path" userInfo:nil];
            }
            QNHTTPDataOperation *operation = [[QNHTTPDataOperation alloc] init];
            operation.path = @"/behaviours";
            operation.method = @"GET";
            QNHTTPDataController *controller = [QNHTTPDataController sharedController];
            controller.basePath = basePath;
            [controller executeOperation:operation withCompletion:^(QNHTTPDataOperation *operation){
                
                if (operation.response && !operation.error) {
                    
                    sharedBehaviours = [[super allocWithZone:NULL] init];
                    sharedBehaviours->behavioursJSON = operation.response;
                } else {
                    
                    NSLog(@"%@ %@", operation.error, operation.response);
                    @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"failed to init behaviours" userInfo:nil];
                }
            }];
        }
    }
    return sharedBehaviours;
}

+ (id)allocWithZone:(NSZone *)zone {
    
    return [[self sharedBehaviours:nil] self];
}

- (id)copyWithZone:(NSZone *)zone {
    
    return self;
}

- (NSString *)basePath {
    
    return [QNHTTPDataController sharedController].basePath;
}

- (void(^)(NSDictionary *, void(^)(NSDictionary *, NSError *)))getBehaviour:(NSString *)behaviourName {
    
    if (!behavioursJSON[behaviourName]) {
        
        return nil;
    }
    return [^(NSDictionary *data, void(^callback)(NSDictionary *, NSError *)) {
        
        NSDictionary *behaviour = behavioursJSON[behaviourName];
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        NSMutableDictionary *body = [NSMutableDictionary dictionary];
        static NSDictionary *parameterTypes = nil;
        if (parameterTypes == nil) {
            
            parameterTypes = @{
              @"header" : @(0),
              @"body" : @(1),
              @"path" : @(2),
              @"query" : @(3)
              };
        }
        for (NSString *key in data) {
            
            switch ([parameterTypes[behaviour[@"parameters"][key][@"type"]] intValue]) {
                case 0:
                    headers[behaviour[@"parameters"][key][@"key"]] = data[key];
                    break;
                case 1:{
                    NSArray *components = [behaviour[@"parameters"][key][@"key"] componentsSeparatedByString:@"."];
                    NSMutableDictionary *subBody = body;
                    for (NSString *component in [components subarrayWithRange:(NSRange){0, components.count - 1}]) {
                        
                        subBody = subBody[component] ? subBody[component] : (subBody[component] = [NSMutableDictionary dictionary]);
                    }
                    subBody[components.lastObject] = data[key];
                }break;
                case 2:
                    break;
                case 3:
                    break;
                default:
                    break;
            }
        }
        QNHTTPDataOperation *operation = [[QNHTTPDataOperation alloc] init];
        operation.path = behaviour[@"path"];
        operation.method = behaviour[@"method"];
        operation.headers = headers.copy;
        operation.body = body.copy;
        QNHTTPDataController *controller = [QNHTTPDataController sharedController];
        [controller executeOperation:operation withCompletion:^(QNHTTPDataOperation *operation){
            
            if (callback) {
                
                callback(operation.response, operation.error);
            }
        }];
    } copy];
}

@end
