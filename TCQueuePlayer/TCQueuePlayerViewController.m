//
//  TCQueuePlayerView.m
//  TCQueuePlayer
//
//  Created by Thibault Charbonnier on 24/05/13.
//  Copyright (c) 2013 thibaultCha. All rights reserved.
//

#import "TCQueuePlayerViewController.h"

@interface TCQueuePlayerViewController ()
{
    float initialRate_;
}
@property (nonatomic, weak) id playerTimeObserver;
@property (nonatomic, strong) UISlider *progressSlider;
- (void)setupPlayer;
- (void)setupControls;
- (void)setupSlider;

- (void)play;
- (void)pause;
- (CMTime)playerItemDuration;
- (void)itemDidFinishPlaying:(NSNotification *)notification;

- (void)addPlayerTimeObserver;
- (void)removePlayerTimeObserver;
- (void)syncSlider;
- (void)didFinishScrollingProgressSlider:(id)sender;
- (void)didBeginScrollingProgressBar:(id)sender;
@end

@implementation TCQueuePlayerViewController


#pragma mark - Dealloc


- (void)dealloc
{
    [self removePlayerTimeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.player];
}

#pragma mark - Init


- (id)initWithItems:(NSArray *)items
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _player = [AVQueuePlayer queuePlayerWithItems:items];
        
        for (AVPlayerItem *item in self.player.items) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(itemDidFinishPlaying:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:item];
        }
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
    [self setupSlider];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self setPlayer:nil];
}


#pragma mark - Controls Setup


- (void)setupPlayer
{
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [playerLayer setFrame:CGRectMake(0,
                                     self.view.frame.size.height/2 - 100.0f,
                                     self.view.frame.size.width,
                                     200.0f)];
    
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
    [playButton addTarget:self
                   action:@selector(play)
         forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *pauseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [pauseButton setFrame:CGRectMake((self.view.frame.size.width/3 - 50.0f) * 3,
                                     30.0f,
                                     100.0f,
                                     50.0f)];
    [pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    [pauseButton addTarget:self
                    action:@selector(pause)
          forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:playButton];
    [self.view addSubview:pauseButton];
}

- (void)setupSlider
{
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(0,
                                                                 self.view.frame.size.height - 50.0f,
                                                                 self.view.frame.size.width,
                                                                 5.0f)];
    [self.progressSlider addTarget:self
                            action:@selector(didBeginScrollingProgressBar:)
                  forControlEvents:UIControlEventTouchDown];
    [self.progressSlider addTarget:self
                            action:@selector(didFinishScrollingProgressSlider:)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.progressSlider setMinimumValue:0];
    [self.progressSlider setValue:0];
    
    [self addPlayerTimeObserver];
    
    [self.view addSubview:self.progressSlider];
}


#pragma mark - Player Methods


- (void)play
{
    [self.player play];
}

- (void)pause
{
    [self.player pause];
}

- (CMTime)playerItemDuration
{
    return [self.player.currentItem duration];
}

- (void)itemDidFinishPlaying:(NSNotification *)notification
{
    if ([self.player.items count] == 1) {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}


#pragma mark - Slider Management


- (void)addPlayerTimeObserver
{
    double interval = .1f;
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth(self.progressSlider.bounds);
        interval = 0.5f * duration / width;
    }
    [self.progressSlider setMaximumValue:duration];
    __weak typeof(self) weakSelf = self;
    _playerTimeObserver = [self.player
                           addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                           queue:nil
                           usingBlock:^(CMTime time) {
                               [weakSelf syncSlider];
                           }];
}

- (void)removePlayerTimeObserver
{
    [self.player removeTimeObserver:self.playerTimeObserver];
    [self setPlayerTimeObserver:nil];
}

- (void)syncSlider
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [self.progressSlider minimumValue];
        float maxValue = [self.progressSlider maximumValue];
        double currentTime = CMTimeGetSeconds([self.player currentTime]);
        
        [self.progressSlider setValue:(maxValue - minValue) * currentTime / duration + minValue];
    }
}

- (void)didBeginScrollingProgressBar:(id)sender
{
    initialRate_ = [self.player rate];
    [self.player setRate:0.f];
    
    [self removePlayerTimeObserver];
}

- (void)didFinishScrollingProgressSlider:(id)sender
{
    if (self.playerTimeObserver == nil) {
        CMTime playerDurection = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDurection)) {
            return;
        }
        double duration = CMTimeGetSeconds(playerDurection);
        if (isfinite(duration)) {
            float minValue = [self.progressSlider minimumValue];
            float maxValue = [self.progressSlider maximumValue];
            double currentTime = [self.progressSlider value];
            
            double time = duration * (currentTime - minValue) / (maxValue - minValue);
            [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
            
            [self addPlayerTimeObserver];
        }
    }
    if (initialRate_) {
        [self.player setRate:initialRate_];
        initialRate_ = 0.f;
    }
}

@end
