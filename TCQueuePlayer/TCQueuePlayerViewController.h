//
//  TCQueuePlayerView.h
//  TCQueuePlayer
//
//  Created by Thibault Charbonnier on 24/05/13.
//  Copyright (c) 2013 thibaultCha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface TCQueuePlayerViewController : UIViewController

@property (nonatomic, strong) AVQueuePlayer *player;

- (id)initWithItems:(NSArray *)items;

@end
