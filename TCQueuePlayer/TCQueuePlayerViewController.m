//
//  TCQueuePlayerView.m
//  TCQueuePlayer
//
//  Created by Thibault Charbonnier on 24/05/13.
//  Copyright (c) 2013 thibaultCha. All rights reserved.
//

#import "TCQueuePlayerViewController.h"

@implementation TCQueuePlayerViewController

- (id)initWithItems:(NSArray *)items
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _player = [AVQueuePlayer queuePlayerWithItems:items];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [playerLayer setFrame:CGRectMake(0,
                                     self.view.frame.size.height/2 - 100.0f,
                                     self.view.frame.size.width,
                                     200.0f)];
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [playButton setFrame:CGRectMake(self.view.frame.size.width/2 - 50.0f,
                                    30.0f,
                                    100.0f,
                                    50.0f)];
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
    [playButton addTarget:self.player
                   action:@selector(play)
         forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:playButton];
    [self.view.layer addSublayer:playerLayer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self setPlayer:nil];
}

@end
