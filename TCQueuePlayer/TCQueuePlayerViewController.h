//
//  TCQueuePlayerView.h
//  TCQueuePlayer
//
//  Created by Thibault Charbonnier on 24/05/13.
//  Copyright (c) 2013 thibaultCha. All rights reserved.
//

typedef NS_OPTIONS(BOOL, TCQueuePlayerControlsState) {
    TCQueuePlayerControlsStateVisible = 0,
    TCQueuePlayerControlsStateHidden = 1
};

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface TCQueuePlayerViewController : UIViewController

@property (nonatomic, strong) AVQueuePlayer *player;
@property (nonatomic, setter = setState:) TCQueuePlayerControlsState state;

- (id)initWithItems:(NSArray *)items;
- (void)animateControlsToState:(TCQueuePlayerControlsState)state;

@end
