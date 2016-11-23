//
//  DataModel.h
//  AVPlayer
//
//  Created by 尹思迁 on 2016/11/23.
//  Copyright © 2016年 尹思迁. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataModel : NSObject

@property (nonatomic, copy) NSString *mp4_url;


- (instancetype)initWithDict:(NSDictionary *)dict;
+ (instancetype)modelWithDict:(NSDictionary *)dict;

@end
