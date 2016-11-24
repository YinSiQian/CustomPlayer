//
//  DataModel.m
//  AVPlayer
//
//  Created by 尹思迁 on 2016/11/23.
//  Copyright © 2016年 尹思迁. All rights reserved.
//

#import "DataModel.h"

@implementation DataModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        _mp4_url = dict[@"mp4_url"];
        _title = dict[@"title"];
        _cover = dict[@"cover"];
    }
    return self;
}

+ (instancetype)modelWithDict:(NSDictionary *)dict {
    return [[self alloc]initWithDict:dict];
}

@end
