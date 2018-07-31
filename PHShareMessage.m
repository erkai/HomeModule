//
//  PHShareMessage.m
//  PHShare
//
//  Created by Mingbao on 7/12/16.
//  Copyright © 2016 qiyi. All rights reserved.
//

#import "PHShareMessage.h"
#import <PHWXSDK/WXApi.h>

@interface PHShareMessage ()

- (NSData *)compressImageTo32k:(UIImage *)image;

@end

@interface MBWechatSessionMessage : PHShareMessage

@end
@implementation MBWechatSessionMessage

- (void)share {
    SendMessageToWXReq *msg = [self generateMessage];
    [WXApi sendReq:msg];
}

- (id)generateMessage {
    SendMessageToWXReq *msg = [[SendMessageToWXReq alloc] init];
    msg.text = self.text;
    msg.bText = self.text.length > 0 ? YES : NO;
    msg.scene = WXSceneSession;
    if (self.image || self.url) {
        WXMediaMessage *media = [WXMediaMessage message];
        media.title = self.title;
        media.description = self.desc;
        if (self.thumbnailImage) {
            media.thumbData = [self compressImageTo32k:self.thumbnailImage];
        }
        if (self.url) {
            WXWebpageObject *webpageObj = [WXWebpageObject object];
            webpageObj.webpageUrl = self.url;
            media.mediaObject = webpageObj;
        } else if (self.image) {
            WXImageObject *image = [WXImageObject object];
            image.imageData = UIImageJPEGRepresentation(self.image, 0.8);
            media.mediaObject = image;
        }
        msg.message = media;

        if (media.mediaObject == nil) {
        }
    }
    return msg;
}

@end

@interface MBWechatTimelineMessage : MBWechatSessionMessage

@end
@implementation MBWechatTimelineMessage

- (id)generateMessage {
    SendMessageToWXReq *msg = [super generateMessage];
    msg.scene = WXSceneTimeline;
    return msg;
}

@end

@implementation PHShareMessage

+ (instancetype)messageWithType:(kShareType)type {
    switch (type) {
        case kShareTypeWechatSession:
            return [[MBWechatSessionMessage alloc] init];
            break;
        case kShareTypeWechatTimeline:
            return [[MBWechatTimelineMessage alloc] init];
            break;
    }
}

- (kShareType)type {
    if ([self isKindOfClass:[MBWechatTimelineMessage class]]) {
        return kShareTypeWechatTimeline;
    } else {
        return kShareTypeWechatSession;
    }
}

- (NSData *)compressImageTo32k:(UIImage *)image {
    CGFloat fractor = 1;
    NSData *thumbnailData = UIImageJPEGRepresentation(image, fractor);
    while (thumbnailData.length > 1024 * 32) {
        fractor *= 0.8;
        thumbnailData = UIImageJPEGRepresentation(self.thumbnailImage, fractor);
    }
    return thumbnailData;
}

- (void)share {
    NSAssert(NO, @"this method must be override");
}

- (id)generateMessage {
    NSAssert(NO, @"this method must be override");
    return nil;
}

@end
