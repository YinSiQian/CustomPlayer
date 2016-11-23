//
//  SQAPIClient.m
//  AVPlayer
//
//  Created by 尹思迁 on 2016/11/23.
//  Copyright © 2016年 尹思迁. All rights reserved.
//

#import "SQAPIClient.h"

@implementation SQAPIClient

+ (instancetype)sharedClient {
    static SQAPIClient *sharedClient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
         //= [NSURLSession sessionWithConfiguration:configuration];
    });
    return sharedClient;
}

- (void)GET:(NSString *)urlString {
    
}

@end
