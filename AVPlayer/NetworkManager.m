//
//  NetworkManager.m
//  AVPlayer
//
//  Created by 尹思迁 on 2016/11/23.
//  Copyright © 2016年 尹思迁. All rights reserved.
//

#import "NetworkManager.h"

@implementation NetworkManager

+ (void)GET:(NSString *)urlString
              success:(void(^)(id responseObject))success
                  failure:(void(^)(NSError *error))failure {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 10;
    NSURLSessionConfiguration *defaultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:defaultConfiguration];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                failure(error);
            } else {
                id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                success(object);
            }
        });
    }];
    [task resume];
    
}


@end
