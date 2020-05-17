//
//  Behaviours_SDK_iOS.h
//  Behaviours-SDK-iOS
//
//  Created by Ahmed Ragab on 2/14/16.
//  Copyright © 2016 QuaNode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QNBehaviours : NSObject {
    
@private NSDictionary *behavioursBody;
@private NSDictionary *behavioursHeaders;
@private void(^errorCallback)(NSError *);
@private NSDictionary *defaults;
@private NSMutableArray *backgroundCallbacks;
@private NSMutableArray *foregroundCallbacks;
    
}

@property (nonatomic, readonly) NSString *baseURL;

+ (QNBehaviours *)sharedBehaviours:(NSString *)baseURL withErrorCallback:(void(^)(NSError *))errorCallback andDefaults:(NSDictionary *)defaults;
- (void)onReady:(void(^)(void))callback;
- (void(^)(NSDictionary *, void(^)(NSDictionary *, NSError *)))getBehaviour:(NSString *)behaviourName;

@end
