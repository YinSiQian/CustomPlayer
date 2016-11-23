//
//  SQPlayer.h
//  AVPlayer
//
//  Created by 尹思迁 on 2016/11/23.
//  Copyright © 2016年 尹思迁. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQPlayer : UIView

@property (nonatomic, strong) NSString *urlString;

- (void)play;

- (void)pause;


@end
