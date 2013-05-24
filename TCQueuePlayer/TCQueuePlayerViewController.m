//
//  TCQueuePlayerView.m
//  TCQueuePlayer
//
//  Created by Thibault Charbonnier on 24/05/13.
//  Copyright (c) 2013 thibaultCha. All rights reserved.
//

static const CGFloat kTimeIntervalSliderObserver = 0.1f;

#import "TCQueuePlayerViewController.h"

@interface TCQueuePlayerViewController ()
@property (nonatomic, strong) UISlider *progressSlider;
- (void)setupPlayer;
- (void)setupControls;
@end

@implementation TCQueuePlayerViewController


#pragma mark - Init


- (id)initWithItems:(NSArray *)items
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _player = [AVQueuePlayer queuePlayerWithItems:items];
    }
    return self;
}


#pragma mark - View Lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    [self setupPlayer];
    [self setupControls];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self setPlayer:nil];
}


#pragma mark - Controls setup


- (void)setupPlayer
{
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [playerLayer setFrame:CGRectMake(0,
                                     self.view.frame.size.height/2 - 100.0f,
                                     self.view.frame.size.width,
                                     200.0f)];
    
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(kTimeIntervalSliderObserver, NSEC_PER_SEC)
                                              queue:nil
                                         usingBlock:^(CMTime time) {
                                             
                                         }];
    
    [self.view.layer addSublayer:playerLayer];
}

- (void)setupControls
{
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [playButton setFrame:CGRectMake((self.view.frame.size.width/3 - 50.0f) * 1,
                                    30.0f,
                                    100.0f,
                                    50.0f)];
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
    [playButton addTarget:self.player
                   action:@selector(play)
         forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *pauseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [pauseButton setFrame:CGRectMake((self.view.frame.size.width/3 - 50.0f) * 3,
                                     30.0f,
                                     100.0f,
                                     50.0f)];
    [pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    [pauseButton addTarget:self.player
                    action:@selector(pause)
          forControlEvents:UIControlEventTouchUpInside];
    
    double duration = CMTimeGetSeconds(self.player.currentItem.duration);
    if (CMTIME_IS_INVALID(duration)) {
        [NSException raise:@"Invalid time duration" format:@"Time duration is invalid"];
    }
#warning - TODO
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(0,
                                                                 self.view.frame.size.height - 50.0f,
                                                                 self.view.frame.size.width,
                                                                 5.0f)];
    [self.progressSlider setMaximumValue:duration];
    [self.progressSlider setValue:0];
    [self.progressSlider setUserInteractionEnabled:NO];
    
    
    
    [self.view addSubview:playButton];
    [self.view addSubview:pauseButton];
    [self.view addSubview:self.progressSlider];
}

@end
