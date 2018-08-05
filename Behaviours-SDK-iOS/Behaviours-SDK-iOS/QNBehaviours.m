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

@interface QNBehaviours (Private)

- (NSDictionary *)parameterFromCache:(NSString *)key;
- (void)setParameterToCache:(NSDictionary *)parameter key:(NSString *)key;
- (id)valueForParameter:(NSDictionary *)parameter data:(NSDictionary *)data key:(NSString *)key name:(NSString *)name;

@end

@implementation QNBehaviours

+ (QNBehaviours *)sharedBehaviours:(NSString *)basePath withDefaults:(NSDictionary *)defaults {
    
    @synchronized(self) {
        
        if (sharedBehaviours == nil) {
            
            if ([[NSThread currentThread] isMainThread]) {
                
                @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"you should create behaviours in background thread first time" userInfo:nil];
            }
            if (!basePath) {
                
                @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"you should provide base path" userInfo:nil];
            }
            NSMutableDictionary *parameters = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Behaviours"] mutableCopy];
            parameters = parameters ? parameters : [NSMutableDictionary dictionary];
            if (defaults) [parameters addEntriesFromDictionary:defaults];
            QNHTTPDataOperation *operation = [[QNHTTPDataOperation alloc] init];
            operation.path = @"/behaviours";
            operation.method = @"GET";
            QNHTTPDataController *controller = [QNHTTPDataController sharedController];
            controller.basePath = basePath;
            [controller executeOperation:operation withCompletion:^(QNHTTPDataOperation *operation){
                
                if (operation.responseBody && !operation.error) {
                    
                    sharedBehaviours = [[super allocWithZone:NULL] init];
                    sharedBehaviours->behavioursJSON = operation.responseBody;
                    sharedBehaviours->parameters = [parameters copy];
                } else {
                    
                    NSLog(@"%@ %@", operation.error, operation.responseBody);
                    @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"failed to init behaviours" userInfo:nil];
                }
            }];
        }
    }
    return sharedBehaviours;
}

+ (id)allocWithZone:(NSZone *)zone {
    
    return [[self sharedBehaviours:nil withDefaults:nil] self];
}

- (id)copyWithZone:(NSZone *)zone {
    
    return self;
}

- (NSString *)basePath {
    
    return [QNHTTPDataController sharedController].basePath;
}

- (id)valueForParameter:(NSDictionary *)parameter data:(NSDictionary *)data key:(NSString *)key name:(NSString *)name {
    
    return data && key && data[key] ? data[key] : (^id(){
        
        id value = parameter[@"value"];
        if ([value isKindOfClass:NSClassFromString(@"NSBlock")]) return ((id(^)(NSString*,NSDictionary*))value)(name, data);
        if (value) return value;
        if ([parameter[@"source"] boolValue]) return [self parameterFromCache:key][key][@"value"];
        return nil;
    }());
}

- (NSDictionary *)parameterFromCache:(NSString *)key {
    
    NSDictionary *params = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Behaviours"];
    return params ? params : key ? @{key:@{}} : @{};
}

- (void)setParameterToCache:(NSDictionary *)parameter key:(NSString *)key {
    
    if (key && [parameter[key][@"source"] boolValue]) {
        
        [[NSUserDefaults standardUserDefaults] setObject:parameter forKey:@"Behaviours"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void(^)(NSDictionary *, void(^)(NSDictionary *, NSError *)))getBehaviour:(NSString *)behaviourName {
    
    if (!behaviourName) @throw [[NSException alloc] initWithName:@"QNBehaviourNameException" reason:@"Invalid behaviour name" userInfo:nil];
    if (!behavioursJSON) @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"Behaviours is not ready yet" userInfo:nil];
    NSDictionary *behaviour = behavioursJSON[behaviourName];
    if (!behaviour) @throw [[NSException alloc] initWithName:@"QNBehaviourNameException" reason:@"This behaviour does not exist" userInfo:nil];
    return [^(NSDictionary *data, void(^callback)(NSDictionary *, NSError *)) {
        
        data = data ? data : [NSDictionary dictionary];
        NSDictionary *params = [self->parameters mutableCopy];
        if (behaviour[@"parameters"]) [(NSMutableDictionary *)params addEntriesFromDictionary:behaviour[@"parameters"]];
        params = [params copy];
        NSArray *keys = [params allKeys];
        __block NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        __block NSMutableDictionary *body = [NSMutableDictionary dictionary];
        NSMutableString *path = [behaviour[@"path"] mutableCopy];
        static NSDictionary *parameterTypes = nil;
        if (parameterTypes == nil) {
            
            parameterTypes = @{
              @"header" : @(1),
              @"body" : @(2),
              @"path" : @(3),
              @"query" : @(4)
              };
        }
        for (NSString *key in keys) {
            
            if(![self valueForParameter:params[key] data:data key:key name:behaviourName]) continue;
            if ([params[key][@"unless"] isKindOfClass:NSArray.class] && [params[key][@"unless"] indexOfObject:behaviourName] > -1) continue;
            if ([params[key][@"for"] isKindOfClass:NSArray.class] && [params[key][@"for"] indexOfObject:behaviourName] == -1) continue;
            switch ([parameterTypes[params[key][@"type"]] intValue]) {
                    
                case 1:
                    headers[params[key][@"key"]] = [self valueForParameter:params[key] data:data key:key name:behaviourName];
                    break;
                case 2:{
                    NSArray *components = [params[key][@"key"] componentsSeparatedByString:@"."];
                    NSMutableDictionary *subBody = body;
                    for (NSString *component in [components subarrayWithRange:(NSRange){0, components.count - 1}]) {
                        
                        subBody = subBody[component] ? subBody[component] : (subBody[component] = [NSMutableDictionary dictionary]);
                    }
                    subBody[components.lastObject] = [self valueForParameter:params[key] data:data key:key name:behaviourName];
                }break;
                case 3:
                    path = [path stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@":%@", key] withString:[[[self valueForParameter:params[key] data:data key:key name:behaviourName] description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]].mutableCopy;
                    break;
                case 4:
                    if (![path containsString:@"?"]) [path appendString:@"?"];
                    [path appendString:[NSString stringWithFormat:@"&%@=%@",[params[key][@"key"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], [[[self valueForParameter:params[key] data:data key:key name:behaviourName] description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
                    break;
                default:
                    break;
            }
        }
        headers[@"Content-Type"] = @"application/json";
        QNHTTPDataOperation *operation = [[QNHTTPDataOperation alloc] init];
        operation.path = path.copy;
        operation.method = behaviour[@"method"];
        operation.headers = headers.copy;
        operation.body = body.copy;
        QNHTTPDataController *controller = [QNHTTPDataController sharedController];
        [controller executeOperation:operation withCompletion:^(QNHTTPDataOperation *operation){
            
            headers = [NSMutableDictionary dictionary];
            body = [NSMutableDictionary dictionary];
            if ([behaviour[@"returns"] isKindOfClass:NSDictionary.class] && [[[behaviour[@"returns"] allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *key, NSDictionary* bindings){
                
                id paramValue, paramKey;
                if ([behaviour[@"returns"][key][@"type"] isEqualToString:@"header"]) {
                    
                    paramKey = behaviour[@"returns"][key][@"key"];
                    paramKey = paramKey ? paramKey : key;
                    paramValue = operation.responseHeaders[key];
                    headers[paramKey] = paramValue;
                }
                if ([behaviour[@"returns"][key][@"type"] isEqualToString:@"body"] && operation.responseBody && !body[key]) {
                    
                    paramKey = key;
                    paramValue = [operation.responseBody[@"response"] isKindOfClass:NSArray.class] ? operation.responseBody[@"response"] : operation.responseBody[@"response"][key];
                    body[paramKey] = paramValue;
                }
                if (behaviour[@"returns"][key][@"purpose"] && paramValue && paramKey) {
                    
                    NSArray *purposes = behaviour[@"returns"][key][@"purpose"];
                    if (![purposes isKindOfClass:NSArray.class]) purposes = @[purposes];
                    static NSDictionary *purposesTypes = nil;
                    if (purposesTypes == nil) {
                        
                        purposesTypes = @{
                                           @"parameter" : @(1)
                                           };
                    }
                    for (__strong id purpose in purposes) {
                        
                        switch ([purposesTypes[[purpose isKindOfClass:NSDictionary.class] ? purpose[@"as"] : purpose] intValue]) {
                                
                            case 1:{
                                
                                NSMutableDictionary *param = [[self parameterFromCache:nil] mutableCopy];
                                param[paramKey] = [@{@"key":key, @"type":behaviour[@"returns"][key][@"type"]} mutableCopy];
                                self->parameters = [self->parameters mutableCopy];
                                ((NSMutableDictionary *)self->parameters)[paramKey] = param[paramKey];
                                if (purpose[@"unless"]) {
                                    
                                    param[paramKey][@"unless"] = purpose[@"unless"];
                                    self->parameters[paramKey][@"unless"] = purpose[@"unless"];
                                }
                                if (purpose[@"for"]) {
                                    
                                    param[paramKey][@"for"] = purpose[@"for"];
                                    self->parameters[paramKey][@"for"] = purpose[@"for"];
                                }
                                for (__strong id p in purposes) {
                                    
                                    if ([p isEqualToString:@"constant"] || ([p isKindOfClass:NSDictionary.class] && [p[@"as"] isEqualToString:@"constant"])) {
                                        
                                        param[paramKey][@"value"] = paramValue;
                                        self->parameters[paramKey][@"value"] = paramValue;
                                        break;
                                    }
                                }
                                param[paramKey][@"source"] = @true;
                                self->parameters[paramKey][@"source"] = @true;
                                [self setParameterToCache:param key:paramKey];
                            }break;
                            default:
                                break;
                        }
                    }
                }
                return [behaviour[@"returns"][key][@"type"] isEqualToString:@"header"];
            }]] count] > 0) {
                
                if (callback) {
                    
                    NSMutableDictionary *response = [headers mutableCopy];
                    [response addEntriesFromDictionary:body.allKeys.count > 0 ? body : @{@"data" : operation.responseBody}];
                    callback([response copy], operation.error);
                }
            } else {
                
                if (callback) {
                    
                    callback(operation.responseBody, operation.error);
                }
            }
        }];
    } copy];
}

@end
