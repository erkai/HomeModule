//
//  PHShareApi.m
//  PHShare
//
//  Created by Mingbao on 7/12/16.
//  Copyright © 2016 qiyi. All rights reserved.
//

#import "PHShareApi.h"
#import "PHShareMessage.h"
#import <PHWXSDK/WXApi.h>
#import <objc/runtime.h>

@interface PHShareApi () <WXApiDelegate>

+ (instancetype)shareInstance;

@property (nonatomic, strong) NSMutableDictionary *globalSettings;

@property (nonatomic, copy) PHShareCompleteCallback callback;

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url;

@end

BOOL handleOpenUrl(id self, SEL cmd, UIApplication *application, NSURL *url) {
    return [[PHShareApi shareInstance] application:application handleOpenURL:url];
}

@implementation PHShareApi

+ (instancetype)shareInstance {
    static PHShareApi *__instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[PHShareApi alloc] init];
    });
    return __instance;
}

+ (void)registerAppKeys:(NSDictionary *)keys {
    [[self shareInstance] registerAppKeys:keys];
}

+ (BOOL)isAppInstalled:(NSString *)platform {
    return [[self shareInstance] isAppInstalled:platform];
}

+ (void)shareMessage:(PHShareMessage *)msg complete:(PHShareCompleteCallback)complete {
    [[self shareInstance] shareMessage:msg complete:complete];
}

- (instancetype)init {
    if (self = [super init]) {
        _globalSettings = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerAppKeys:(NSDictionary *)keys {
    NSArray *allKeys = keys.allKeys;
    for (NSString *key in allKeys) {
        NSString *lowercaseKey = key.lowercaseString;
        if ([lowercaseKey isEqualToString:@"wechat"] || [lowercaseKey isEqualToString:@"weixin"]) {
            [WXApi registerApp:[keys objectForKey:key]];
        }
    }
}

- (BOOL)isAppInstalled:(NSString *)platform {
    BOOL installed = NO;
    NSString *lowercasePlatform = platform.lowercaseString;
    if ([lowercasePlatform isEqualToString:@"wechat"] || [lowercasePlatform isEqualToString:@"weixin"]) {
        installed = [WXApi isWXAppInstalled];
    }
    return installed;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    id delegate = [UIApplication sharedApplication].delegate;
    IMP delegateIMP = class_getMethodImplementation([delegate class], @selector(application:handleOpenURL:));
    IMP mbIMP = class_getMethodImplementation([PHShareApi class], @selector(application:handleOpenURL:));
    if (delegateIMP == mbIMP) { //添加方法
        return [[PHShareApi shareInstance] handleOpenURL:url];
    } else {
        [[PHShareApi shareInstance] handleOpenURL:url];
        return [[PHShareApi shareInstance] application:application handleOpenURL:url];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(id)annotation {
    id delegate = [UIApplication sharedApplication].delegate;
    IMP delegateIMP = class_getMethodImplementation([delegate class], @selector(application:openURL:sourceApplication:annotation:));
    IMP mbIMP = class_getMethodImplementation([PHShareApi class], @selector(application:openURL:sourceApplication:annotation:));
    if (delegateIMP == mbIMP) { //添加方法
        return [[PHShareApi shareInstance] handleOpenURL:url];
    } else {
        [[PHShareApi shareInstance] handleOpenURL:url];
        return [[PHShareApi shareInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
}

- (void)hookAppDelegate:(id)delegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selector = @selector(application:handleOpenURL:);

        Class delegateClass = [delegate class];
        Class selfClass = [self class];

        Method method = class_getInstanceMethod(selfClass, selector);
        BOOL didAddMethod = class_addMethod(delegateClass, selector, class_getMethodImplementation(selfClass, selector), method_getTypeEncoding(method));
        if (!didAddMethod) {
            Method delegateMethod = class_getInstanceMethod(delegateClass, selector);
            method_exchangeImplementations(method, delegateMethod);
        }

        SEL openUrlSelector = @selector(application:openURL:sourceApplication:annotation:);
        Method openUrlmethod = class_getInstanceMethod(selfClass, openUrlSelector);

        BOOL didAddOpenUrlMethod = class_addMethod(delegateClass, openUrlSelector, class_getMethodImplementation(selfClass, openUrlSelector), method_getTypeEncoding(openUrlmethod));
        if (!didAddOpenUrlMethod) {
            Method delegateOpenUrlMethod = class_getInstanceMethod(delegateClass, openUrlSelector);
            method_exchangeImplementations(openUrlmethod, delegateOpenUrlMethod);
        }
    });
}

- (BOOL)handleOpenURL:(NSURL *)url {
    if ([WXApi handleOpenURL:url delegate:self]) {
        return YES;
    }
    return NO;
}

- (void)shareMessage:(PHShareMessage *)msg complete:(PHShareCompleteCallback)complete {
    if (complete) {
        self.callback = complete;
    }
    [msg share];
}

- (void)completeShareMessage:(PHShareMessage *)msg state:(kPHShareState)state error:(NSError *)error {
    if (self.callback) {
        self.callback(state, nil, error);
        self.callback = nil;
    }
}

#pragma WeiboSDK Delegate

- (void)onResp:(BaseResp *)resp {
    kPHShareState state;
    NSError *error = nil;
    switch (resp.errCode) {
        case WXSuccess:
            state = kPHShareStateSuccess;
            break;
        case WXErrCodeUserCancel:
            state = kPHShareStateCancelled;
//            error = [NSError errorWithDomain:@"PHShareApi::Weibo" code:resp.errCode userInfo:@{ NSLocalizedDescriptionKey : PHLocalizedString(@"s_micro_blog_share_canceled_tip") }];
            break;
        case WXErrCodeCommon:
        //            state = kPHShareStateFailed;
        //            break;
        case WXErrCodeSentFail:
        //            state = kPHShareStateFailed;
        //            break;
        case WXErrCodeAuthDeny:
        //            state = kPHShareStateFailed;
        //            break;
        case WXErrCodeUnsupport:
            state = kPHShareStateFailed;
            error = [NSError errorWithDomain:@"PHShareApi::Weibo" code:resp.errCode userInfo:(resp.errStr ? @{NSLocalizedDescriptionKey : resp.errStr} : nil)];
            break;
        default:
            break;
    }
    [self completeShareMessage:nil state:state error:error];
}

#pragma WXApi Delegate


@end

@interface UIApplication (PHShare)

@end

@implementation UIApplication (PHShare)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        SEL originalSelector = @selector(setDelegate:);
        SEL swizzledSelector = @selector(mb_setDelegate:);

        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);

        BOOL didAddMethod =
            class_addMethod(self,
                            originalSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(self,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }

    });
}

- (void)mb_setDelegate:(id)delegate {
    [[PHShareApi shareInstance] hookAppDelegate:delegate];
    [self mb_setDelegate:delegate];
}

@end
