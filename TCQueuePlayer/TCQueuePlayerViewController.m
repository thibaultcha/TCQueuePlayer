//
//  TCQueuePlayerView.m
//  TCQueuePlayer
//
//  Created by Thibault Charbonnier on 24/05/13.
//  Copyright (c) 2013 thibaultCha. All rights reserved.
//

static const CGFloat kControlsViewOpacity = 0.8f;
static const CGFloat kControlsAnimationDuration = 0.2f;

#import "TCQueuePlayerViewController.h"

@interface TCQueuePlayerViewController ()
{
    float initialRate_;
}
@property (nonatomic, weak) id playerTimeObserver;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIView *topControlsView;
@property (nonatomic, strong) UIView *bottomControlsView;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *pauseButton;
@property (nonatomic, strong) UISlider *progressSlider;
// View layout
- (void)setupControls;
- (void)setupPlayer;
- (void)setupButtons;
- (void)setupProgressSlider;
- (void)setupAudioSlider;
// Player
- (void)play;
- (void)pause;
- (CMTime)playerItemDuration;
- (void)itemDidFinishPlaying:(NSNotification *)notification;
// Utilities
- (void)addPlayerTimeObserver;
- (void)removePlayerTimeObserver;
- (void)syncSlider;
- (void)didFinishScrollingProgressSlider:(id)sender;
- (void)didBeginScrollingProgressBar:(id)sender;
// Gesture
- (void)didTapControlsView:(UIGestureRecognizer *)gesture;
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
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    
    [self setupPlayer];
    [self setupControls];
    [self setState:TCQueuePlayerControlsStateVisible];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self setPlayer:nil];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.playerLayer setFrame:CGRectMake(0,
                                          self.view.bounds.size.height/2 - self.view.bounds.size.height/2,
                                          self.view.bounds.size.width,
                                          self.view.bounds.size.height)];
}


#pragma mark - Controls Setup


- (void)setupPlayer
{
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.playerLayer setFrame:CGRectMake(0,
                                          self.view.bounds.size.height/2 - self.view.bounds.size.height/2,
                                          self.view.bounds.size.width,
                                          self.view.bounds.size.height)];

    [self.view.layer addSublayer:self.playerLayer];
}

- (void)setupControls
{
    _topControlsView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                0,
                                                                self.view.frame.size.width,
                                                                50.0f)];
    [self.topControlsView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.topControlsView setBackgroundColor:[UIColor darkGrayColor]];
    
    _bottomControlsView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                   self.view.frame.size.height - 50.0f,
                                                                   self.view.frame.size.width,
                                                                   50.0f)];
    [self.bottomControlsView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.bottomControlsView setBackgroundColor:[UIColor darkGrayColor]];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                                   action:@selector(didTapControlsView:)];
    [tapGesture setNumberOfTapsRequired:1];
    [tapGesture setNumberOfTouchesRequired:1];
    
    [self.view addGestureRecognizer:tapGesture];
    [self.view addSubview:self.topControlsView];
    [self.view addSubview:self.bottomControlsView]; 
    
    [self setupButtons];
    [self setupProgressSlider];
    [self setupAudioSlider];
}

- (void)setupButtons
{
    _playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.playButton setFrame:CGRectMake(10.0f,
                                         0,
                                         100.0f,
                                         50.0f)];
    [self.playButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.playButton addTarget:self
                   action:@selector(play)
         forControlEvents:UIControlEventTouchUpInside];
    
    _pauseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.pauseButton setFrame:self.playButton.frame];
    [self.pauseButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [self.pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    [self.pauseButton addTarget:self
                    action:@selector(pause)
          forControlEvents:UIControlEventTouchUpInside];
    
    [self.playButton setHidden:NO];
    [self.pauseButton setHidden:YES];
    [self.topControlsView addSubview:self.playButton];
    [self.topControlsView addSubview:self.pauseButton];
}

- (void)setupProgressSlider
{
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(0,
                                                                 self.bottomControlsView.frame.size.height/2 - 5.0f,
                                                                 self.view.frame.size.width,
                                                                 5.0f)];
    [self.progressSlider setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [self.progressSlider addTarget:self
                            action:@selector(didBeginScrollingProgressBar:)
                  forControlEvents:UIControlEventTouchDown];
    [self.progressSlider addTarget:self
                            action:@selector(didFinishScrollingProgressSlider:)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.progressSlider setMinimumValue:0];
    [self.progressSlider setValue:0];
    
    [self addPlayerTimeObserver];
    
    [self.bottomControlsView addSubview:self.progressSlider];
}

- (void)setupAudioSlider
{
    MPVolumeView *volumeSlider = [[MPVolumeView alloc] initWithFrame:CGRectMake(120.0f,
                                                                                self.topControlsView.frame.size.height/2 - 10.0f,
                                                                                200.0f,
                                                                                20.0f)];
    [volumeSlider setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [volumeSlider setShowsVolumeSlider:YES];
    [volumeSlider setShowsRouteButton:YES];
    
    [self.topControlsView addSubview:volumeSlider];
}


#pragma mark - Public methods


- (void)animateControlsToState:(TCQueuePlayerControlsState)state
{
    CGFloat opacity = 0;
    CGFloat alpha = 0;
    if (state == TCQueuePlayerControlsStateVisible) {
        opacity = kControlsViewOpacity;
        alpha =1.0f;
    }
    
    [UIView animateWithDuration:kControlsAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         [self.topControlsView setBackgroundColor
                          :[[UIColor blackColor] colorWithAlphaComponent:opacity]];
                         [self.bottomControlsView setBackgroundColor
                          :[[UIColor blackColor] colorWithAlphaComponent:opacity]];
                         [self.topControlsView setAlpha:alpha];
                         [self.bottomControlsView setAlpha:alpha];
                     }
                     completion:nil];
}


#pragma mark - Setters


- (void)setState:(TCQueuePlayerControlsState)state
{
    _state = state;
    [self animateControlsToState:state];
}


#pragma mark - Gesture Management


- (void)didTapControlsView:(UIGestureRecognizer *)gesture
{
    [self setState:!self.state];
}


#pragma mark - AVPlayer Methods


- (void)play
{
    [self.playButton setHidden:YES];
    [self.pauseButton setHidden:NO];
    
    [self.player play];
}

- (void)pause
{
    [self.pauseButton setHidden:YES];
    [self.playButton setHidden:NO];
    
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


#pragma mark - Progress Slider Management


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
