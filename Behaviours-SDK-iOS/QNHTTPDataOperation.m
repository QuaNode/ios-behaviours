//
//  QNHTTPDataOperation.m
//  QuaNode
//
//  Created by Ahmed Ragab on 1/19/16.
//  Copyright © 2016 quanode.com. All rights reserved.
//

#import "QNHTTPDataOperation.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#else
#import <AppKit/NSScreen.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>
NSString * machineModel() {
    
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    if (len)
    {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        return model_ns;
    }
    return @"Just an Apple Computer"; //incase model name can't be read
}
#endif

static NSString *model;
static NSString *version;
static float scale;
static NSString *systemSymbol;

@implementation NSError (Message)

- (NSString *)message {
    
    return self.userInfo[NSLocalizedFailureReasonErrorKey];
}

@end

@implementation QNHTTPDataOperation

+ (void)load {
    
#if TARGET_OS_IPHONE
    model = [[UIDevice currentDevice] model];
    version = [[UIDevice currentDevice] systemVersion];
    scale = ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f);
    systemSymbol = @"iOS";
#else
    model = machineModel();
    version = [[NSProcessInfo processInfo] operatingSystemVersionString];
    if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)]) {
        
        NSArray *screens = [NSScreen screens];
        for (int i = 0; i < [screens count]; i++) {
            
            float s = [[screens objectAtIndex:i] backingScaleFactor];
            if (s > scale) scale = s;
        }
    } else {
        
        scale = 1.0f;
    }
    systemSymbol = @"Mac OS";
#endif
}

- (NSDictionary *)headers {
    
    NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
    return @{
         @"Accept-Language" :[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes],
         @"User-Agent" : [NSString stringWithFormat:@"%@/%@ (%@; %@ %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], model, systemSymbol, version,scale]
    };
}

@end
