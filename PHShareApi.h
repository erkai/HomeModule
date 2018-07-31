//
//  PHShareApi.h
//  PHShare
//
//  Created by Mingbao on 7/12/16.
//  Copyright © 2016 qiyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PHShareMessage.h"

typedef NS_ENUM(NSUInteger, kPHShareState) {
    kPHShareStateSuccess = 0,
    kPHShareStateCancelled = -1,
    kPHShareStateFailed = -2
};

typedef void(^PHShareCompleteCallback)(kPHShareState state, NSDictionary *userInfo, NSError *error);

@interface PHShareApi : NSObject

/**
 * @brief 注册平台信息
 * @param keys 各个平台注册的Appkey
 * @description 示例
 *              @code     [PHShareApi registerAppKeys: @{@"Weibo": @"微博appkey", @"Wechat": @"微信appkey"}];
 */
+ (void) registerAppKeys: (NSDictionary *) keys;

/**
 * @brief 判断平台App是否安装(目前支持微信、微博)
 * @param platform 平台名称,支持weibo,wechat,不区分大小写
 * @description 示例
 *              @code [PHShareApi isAppInstalled: @"wechat"]
 */
+ (BOOL) isAppInstalled: (NSString *) platform;

/**
 * @brief 分享
 * @param msg 分享内容
 * @param complete分享完成之后的回调
 * @brief 示例
 *        @code PHShareMessage *message = [PHShareMessage messageWithType: kShareTypeWechatSession];
 message.title = @"永久免费的爱奇艺安全利器";
 message.desc = @"推荐你一个爱奇艺防盗神器，从此安全无忧";
 message.url = @"http://71.am/q7";
 message.image = [UIImage imageNamed: @"qis_download_qr"];
 message.thumbnailImage = message.image;
 [PHShareApi shareMessage: message complete:^(kPHShareState state, NSDictionary *userInfo, NSError *error) {
 NSLog(@"shareWeibo %@", @(state));
 }];
 
 */
+ (void) shareMessage: (PHShareMessage *) msg complete: (PHShareCompleteCallback) complete;

@end
