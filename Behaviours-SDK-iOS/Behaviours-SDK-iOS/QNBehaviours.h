//
//  Behaviours_SDK_iOS.h
//  Behaviours-SDK-iOS
//
//  Created by Ahmed Ragab on 2/14/16.
//  Copyright © 2016 QuaNode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QNBehaviours : NSObject {
    
@private NSDictionary *behavioursJSON;
    
}

@property (nonatomic, readonly) NSString *basePath;

+ (QNBehaviours *)sharedBehaviours:(NSString *)basePath;

- (void(^)(NSDictionary *, void(^)(NSDictionary *, NSError *)))getBehaviour:(NSString *)behaviourName;

@end
