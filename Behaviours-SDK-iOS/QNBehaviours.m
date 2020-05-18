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
#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, Type) {
    
    TypeHeader = 1,
    TypeBody = 2,
    TypePath = 3,
    TypeQuery = 4
};

Type TypeFromString(NSString *type) {
    
    static NSDictionary *types = nil;
    if (types == nil) {
        
        types = @{
            @"header" : @(TypeHeader),
            @"body" : @(TypeBody),
            @"path" : @(TypePath),
            @"query" : @(TypeQuery)
        };
    }
    return (NSUInteger)[types[type] intValue];
}

BOOL isTypeHeader(NSString *type) {
    
    return TypeFromString(type) == TypeHeader;
}

BOOL isTypeBody(NSString *type) {
    
    return TypeFromString(type) == TypeBody;
}

typedef NS_ENUM(NSUInteger, Purpose) {
    
    PurposeConstant = 1,
    PurposeParameter = 2
};

Purpose PurposeFromString(NSString *purpose) {
    
    static NSDictionary *purposes = nil;
    if (purposes == nil) {
        
        purposes = @{
            @"constant" : @(PurposeConstant),
            @"parameter" : @(PurposeParameter)
        };
    }
    return (NSUInteger)[purposes[purpose] intValue];
}

BOOL isPurposeConstant(NSString *purpose) {
    
    return PurposeFromString(purpose) == PurposeConstant;
}

BOOL isPurposeParameter(NSString *purpose) {
    
    return PurposeFromString(purpose) == PurposeParameter;
}


@interface NSDictionary (Behaviour)

@property (nonatomic, readonly) NSString *method;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSDictionary *parameters;
@property (nonatomic, readonly) NSDictionary *returns;

@end

@implementation NSDictionary (Behaviour)

- (NSString *)method {
    
    return self[@"method"];
}

- (NSString *)path {
    
    return self[@"path"];
}

- (NSDictionary *)parameters {
    
    return self[@"parameters"];
}

- (NSDictionary *)returns {
    
    return self[@"returns"];
}

@end

@interface NSDictionary (ParameterAndReturn)

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) id value;
@property (nonatomic, readonly) NSNumber *source;
@property (nonatomic, readonly) NSArray *purpose;

@end

@implementation NSDictionary (ParameterAndReturn)

- (NSString *)key {
    
    return self[@"key"];
}

- (NSString *)type {
    
    return self[@"type"];
}

- (id)value {
    
    return self[@"value"];
}

- (NSNumber *)source {
    
    return self[@"source"];
}

- (NSArray *)purpose {
    
    return self[@"purpose"];
}

@end

@interface NSMutableDictionary (ParameterAndReturnExtended)

- (void)setValue:(id)value;
- (void)setSource:(NSNumber *)source;

@end

@implementation NSMutableDictionary (ParameterAndReturnExtended)

- (void)setValue:(id)value {
    
    self[@"value"] = value;
}

- (void)setSource:(NSNumber *)source {
    
    self[@"source"] = source;
}

@end

@interface NSDictionary (Purpose)

@property (nonatomic, readonly) NSString *as;
@property (nonatomic, readonly) NSArray *unless;
@property (nonatomic, readonly) NSArray *ḟor;

@end

@implementation NSDictionary (Purpose)

- (NSString *)as {
    
    return self[@"as"];
}

- (NSArray *)unless {
    
    return self[@"unless"];
}

- (NSArray *)ḟor {
    
    return self[@"for"];
}

@end

@interface NSMutableDictionary (PurposeExtended)

- (void)setUnless:(NSArray *)unless;
- (void)setFor:(NSArray *)ḟor;

@end

@implementation NSMutableDictionary (PurposeExtended)

- (void)setUnless:(NSArray *)unless {
    
    self[@"unless"] = unless;
}

- (void)setFor:(NSArray *)ḟor {
    
    self[@"for"] = ḟor;
}

@end

static QNBehaviours *sharedBehaviours = nil;

@interface QNBehaviours (Private)

- (NSDictionary *)parameterFromCache:(NSString *)key;
- (void)setParameterToCache:(NSDictionary *)parameter key:(NSString *)key;
- (id)valueForParameter:(NSDictionary *)parameter data:(NSDictionary *)data key:(NSString *)key name:(NSString *)name;

@end

@implementation QNBehaviours

+ (QNBehaviours *)sharedBehaviours:(NSString *)baseURL withErrorCallback:(void(^)(NSError *))errorCallback andDefaults:(NSDictionary *)defaults {
    
    @synchronized(self) {
        
        if (sharedBehaviours == nil) {
            
            if ([[NSThread currentThread] isMainThread]) {
                
                @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"you should create behaviours in background thread first time" userInfo:nil];
            }
            if (!baseURL) {
                
                @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"you should provide base URL" userInfo:nil];
            }
            QNHTTPDataOperation *operation = [[QNHTTPDataOperation alloc] init];
            operation.path = @"/behaviours";
            operation.method = @"GET";
            QNHTTPDataController *controller = [QNHTTPDataController sharedController];
            controller.baseURL = baseURL;
            [controller executeOperation:operation withCompletion:^(QNHTTPDataOperation *operation) {
                
                if (operation.responseBody && !operation.error) {
                    
                    sharedBehaviours = [[super allocWithZone:NULL] init];
                    sharedBehaviours->behavioursBody = operation.responseBody;
                    sharedBehaviours->behavioursHeaders = @{
                        @"Content-Type": operation.responseHeaders[@"Content-Type"]
                    };
                    if ([sharedBehaviours->behavioursBody isKindOfClass:NSDictionary.class]) {
                        
                        for (NSString *key in [sharedBehaviours->behavioursBody allKeys]) {
                            
                            SEL selectorA = NSSelectorFromString([key stringByAppendingString:@"With:andCompletion:"]);
                            SEL selectorB = NSSelectorFromString([key stringByAppendingString:@"::"]);
                            BOOL hasSelectorB = class_respondsToSelector([sharedBehaviours class], selectorB);
                            IMP behaviourImplementation = imp_implementationWithBlock([^void(id self, NSDictionary *behaviourData, void(^completion)(NSDictionary *, NSError *)) {
                                
                                [sharedBehaviours getBehaviour:key](behaviourData, completion);
                            } copy]);
                            NSString *typeEncoding = [NSString stringWithFormat:@"%s%s%s%s", @encode(void), @encode(id), @encode(NSDictionary *), @encode(void(^)(NSDictionary *, NSError *))];
                            class_replaceMethod([sharedBehaviours class], hasSelectorB ? selectorB : selectorA, behaviourImplementation, [typeEncoding UTF8String]);
                            imp_removeBlock(behaviourImplementation);
                        }
                        for (void(^callback)(void) in sharedBehaviours->backgroundCallbacks) {
                            
                            callback();
                        }
                        for (void(^callback)(void) in sharedBehaviours->foregroundCallbacks) {
                            
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                
                                callback();
                            }];
                        }
                    }
                    sharedBehaviours->errorCallback = [errorCallback copy];
                    sharedBehaviours->defaults = [defaults copy];
                } else {
                    
                    @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"Error in initializing Behaviours" userInfo:nil];
                }
            }];
        }
    }
    return sharedBehaviours;
}

+ (id)allocWithZone:(NSZone *)zone {
    
    return [[self sharedBehaviours:nil withErrorCallback:nil andDefaults:nil] self];
}

- (id)copyWithZone:(NSZone *)zone {
    
    return self;
}

- (NSString *)baseURL {
    
    return [QNHTTPDataController sharedController].baseURL;
}

- (void)onReady:(void(^)(void))callback {
    
    if (![callback isKindOfClass:NSClassFromString(@"NSBlock")]) return;
    if (!behavioursBody) {
        
        NSMutableArray *callbacks = [[NSThread currentThread] isMainThread] ? (foregroundCallbacks ?: (foregroundCallbacks = [NSMutableArray array])) : (backgroundCallbacks ?: (backgroundCallbacks = [NSMutableArray array]));
        [callbacks addObject:callback];
    } else callback();
}

- (id)valueForParameter:(NSDictionary *)parameter data:(NSDictionary *)data key:(NSString *)key name:(NSString *)name {
    
    return data && key && data[key] != nil ? data[key] : (^id(){
        
        id value = parameter.value;
        if ([value isKindOfClass:NSClassFromString(@"NSBlock")]) return ((id(^)(NSString*,NSDictionary*))value)(name, data);
        if (value) return value;
        if ([parameter.source boolValue]) return [(NSDictionary *)[self parameterFromCache:key][key] value];
        return nil;
    }());
}

- (NSDictionary *)parameterFromCache:(NSString *)key {
    
    NSDictionary *params = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Behaviours"];
    return params ? params : key ? @{key:@{}} : @{};
}

- (void)setParameterToCache:(NSDictionary *)parameter key:(NSString *)key {
    
    if (key && [[parameter[key] source] boolValue]) {
        
        [[NSUserDefaults standardUserDefaults] setObject:parameter forKey:@"Behaviours"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void(^)(NSDictionary *, void(^)(NSDictionary *, NSError *)))getBehaviour:(NSString *)behaviourName {
    
    if (!behaviourName) @throw [[NSException alloc] initWithName:@"QNBehaviourNameException" reason:@"Invalid behaviour name" userInfo:nil];
    if (!behavioursBody) @throw [[NSException alloc] initWithName:@"QNBehavioursInitException" reason:@"Behaviours is not ready yet" userInfo:nil];
    NSDictionary *behaviour = behavioursBody[behaviourName];
    if (!behaviour) @throw [[NSException alloc] initWithName:@"QNBehaviourNameException" reason:@"This behaviour does not exist" userInfo:nil];
    return [^(NSDictionary *behaviourData, void(^completion)(NSDictionary *, NSError *)) {
        
        behaviourData = behaviourData ? behaviourData : [NSDictionary dictionary];
        NSMutableDictionary *parameters = [[self parameterFromCache:nil] mutableCopy] ?: [NSMutableDictionary dictionary];
        if ([self->defaults isKindOfClass:NSDictionary.class]) [parameters addEntriesFromDictionary:self->defaults];
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        if (behaviour.parameters) {
            
            for (NSString *key in [behaviour.parameters allKeys]) {
                
                params[key] = parameters[key] ?: behaviour.parameters[key];
            }
        }
        NSArray *keys = [params allKeys];
        __block NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers addEntriesFromDictionary:self->behavioursHeaders];
        __block NSMutableDictionary *body = [NSMutableDictionary dictionary];
        NSMutableString *path = behaviour.path.mutableCopy;
        for (NSString *key in keys) {
            
            NSDictionary *param = params[key];
            if (![param isKindOfClass:NSDictionary.class]) continue;
            id value = [self valueForParameter:param data:behaviourData key:key name:behaviourName];
            Type type = TypeFromString(param.type);
            if(value == nil && type != TypePath) continue;
            if ([param.unless isKindOfClass:NSArray.class] && [param.unless indexOfObject:behaviourName] > -1) continue;
            if ([param.ḟor isKindOfClass:NSArray.class] && [param.ḟor indexOfObject:behaviourName] == -1) continue;
            switch (type) {
                    
                case TypeHeader:
                    headers[param.key] = value;
                    break;
                case TypeBody: {
                    NSArray *components = [param.key componentsSeparatedByString:@"."];
                    NSMutableDictionary *subBody = body;
                    for (NSString *component in [components subarrayWithRange:(NSRange){0, components.count - 1}]) {
                        
                        subBody = subBody[component] ? subBody[component] : (subBody[component] = [NSMutableDictionary dictionary]);
                    }
                    if (components.lastObject) subBody[components.lastObject] = value;
                } break;
                case TypePath: {
                    NSString *urlEncodedValue = [[value description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                    path = [path stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@":%@", key] withString:value ? urlEncodedValue : @"*"].mutableCopy;
                } break;
                case TypeQuery: {
                    NSString *urlEncodedKey = [param.key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                    NSString *urlEncodedValue = [[value description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                    NSString *and = @"&";
                    if (![path containsString:@"?"]) {
                        
                        [path appendString:@"?"];
                        and = @"";
                    }
                    [path appendString:[NSString stringWithFormat:@"%@%@=%@", and, urlEncodedKey, urlEncodedValue]];
                } break;
                default: break;
            }
        }
        void(^_)(NSString *);
        void(^request)(NSString *);
        request = _ = ^(NSString *signature) {
                        
            QNHTTPDataOperation *operation = [[QNHTTPDataOperation alloc] init];
            operation.path = path.copy;
            operation.method = behaviour.method;
            if (signature) {
                
                NSMutableDictionary *signedHeaders = @{
                    @"Behaviour-Signature": signature
                }.mutableCopy;
                [signedHeaders addEntriesFromDictionary:headers];
                operation.headers = signedHeaders.copy;
            } else {
                
                operation.headers = headers.copy;
            }
            operation.body = body.copy;
            QNHTTPDataController *controller = [QNHTTPDataController sharedController];
            [controller executeOperation:operation withCompletion:^(QNHTTPDataOperation *operation){
                
                if (operation.error && self->errorCallback) self->errorCallback(operation.error);
                NSString *sig = operation.responseBody ? operation.responseBody[@"signature"] : nil;
                if (sig) return request(sig);
                headers = [NSMutableDictionary dictionary];
                body = [NSMutableDictionary dictionary];
                if ([behaviour.returns isKindOfClass:NSDictionary.class] && [[[behaviour.returns allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *key, NSDictionary* bindings){
                    
                    id paramValue, paramKey;
                    if (isTypeHeader([(NSDictionary *) behaviour.returns[key] type])) {
                        
                        paramKey = [behaviour.returns[key] key];
                        paramKey = paramKey ? paramKey : key;
                        paramValue = operation.responseHeaders[key];
                        headers[paramKey] = paramValue;
                    }
                    if (isTypeBody([(NSDictionary *)behaviour.returns[key] type]) && operation.responseBody && !body[key]) {
                        
                        paramKey = key;
                        paramValue = [operation.responseBody[@"response"] isKindOfClass:NSArray.class] ? operation.responseBody[@"response"] : operation.responseBody[@"response"][key];
                        body[paramKey] = paramValue;
                    }
                    if ([behaviour.returns[key] purpose] && paramValue && paramKey) {
                        
                        NSArray *purposes = [behaviour.returns[key] purpose];
                        if (![purposes isKindOfClass:NSArray.class]) purposes = @[purposes];
                        for (__strong NSDictionary *purpose in purposes) {
                            
                            switch (PurposeFromString([purpose isKindOfClass:NSDictionary.class] ? purpose.as : (NSString *)purpose)) {
                                    
                                case 1:{
                                    
                                    NSMutableDictionary *param = [[self parameterFromCache:nil] mutableCopy];
                                    param[paramKey] = @{
                                        @"key":key,
                                        @"type":[(NSDictionary *)behaviour.returns[key] type]
                                    }.mutableCopy;
                                    parameters[paramKey] = param[paramKey];
                                    if (purpose.unless) {
                                        
                                        [param[paramKey] setUnless:purpose.unless];
                                        [parameters[paramKey] setUnless:purpose.unless];
                                    }
                                    if (purpose.ḟor) {
                                        
                                        [param[paramKey] setFor:purpose.ḟor];
                                        [parameters[paramKey] setFor:purpose.ḟor];
                                    }
                                    for (__strong NSDictionary *otherPurpose in purposes) {
                                        
                                        if (([otherPurpose isKindOfClass:NSDictionary.class] && isPurposeConstant(otherPurpose.as)) || isPurposeConstant((NSString *)otherPurpose )) {
                                            
                                            [(NSMutableDictionary *)param[paramKey] setValue:paramValue];
                                            [(NSMutableDictionary *)parameters[paramKey] setValue:paramValue];
                                            break;
                                        }
                                    }
                                    [param[paramKey] setSource:@true];
                                    [parameters[paramKey] setSource:@true];
                                    [self setParameterToCache:param key:paramKey];
                                } break;
                                default: break;
                            }
                        }
                    }
                    return isTypeHeader([(NSDictionary *)behaviour.returns[key] type]);
                }]] count] > 0) {
                    
                    if (completion) {
                        
                        NSMutableDictionary *response = headers.mutableCopy;
                        [response addEntriesFromDictionary:body.allKeys.count > 0 ? body : @{
                            @"data" : operation.responseBody
                        }];
                        completion([response copy], operation.error);
                    }
                } else {
                    
                    if (completion) {
                        
                        completion(operation.responseBody, operation.error);
                    }
                }
            }];
        };
        request(nil);
    } copy];
}

@end
