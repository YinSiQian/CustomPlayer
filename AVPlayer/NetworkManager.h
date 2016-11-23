//
//  NetworkManager.h
//  AVPlayer
//
//  Created by 尹思迁 on 2016/11/23.
//  Copyright © 2016年 尹思迁. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkManager : NSObject
+ (void)GET:(NSString *)urlString
    success:(void(^)(id responseObject))success
    failure:(void(^)(NSError *error))failure;
@end
