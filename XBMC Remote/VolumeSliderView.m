//
//  VolumeSliderView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "VolumeSliderView.h"
#import "GlobalData.h"
#import "DSJSONRPC.h"
#import "AppDelegate.h"
#import "Utilities.h"

#define VOLUMEICON_PADDING 10 /* space left/right from volume icons */
#define VOLUMEVIEW_OFFSET 8 /* vertical offset to match menu */
#define VOLUMESLIDER_HEIGHT 44
#define SERVER_TIMEOUT 3.0

@implementation VolumeSliderView

@synthesize timer, holdVolumeTimer;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        Utilities *utils = [[Utilities alloc] init];
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VolumeSliderView" owner:self options:nil];
		self = [nib objectAtIndex:0];
        UIImage *img = [UIImage imageNamed:@"pgbar_thumb_iOS7"];
        img = [utils colorizeImage:img withColor:SLIDER_DEFAULT_COLOR];
        [volumeSlider setMinimumTrackTintColor:SLIDER_DEFAULT_COLOR];
        [volumeSlider setMaximumTrackTintColor:APP_TINT_COLOR];
        [volumeSlider setThumbImage:img forState:UIControlStateNormal];
        [volumeSlider setThumbImage:img forState:UIControlStateHighlighted];
        [self volumeInfo];
        volumeSlider.tag = 10;
        [volumeSlider addTarget:self action:@selector(changeServerVolume:) forControlEvents:UIControlEventTouchUpInside];
        [volumeSlider addTarget:self action:@selector(changeServerVolume:) forControlEvents:UIControlEventTouchUpOutside];
        [volumeSlider addTarget:self action:@selector(stopTimer) forControlEvents:UIControlEventTouchDown];
        CGRect frame_tmp;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            volumeLabel.alpha = 0.8;
            volumeView.hidden = YES;
            volumeSlider.hidden = YES;
            
            frame_tmp = muteButton.frame;
            frame_tmp.origin.x = 0;
            muteButton.frame = frame_tmp;
            
            frame_tmp = minusButton.frame;
            frame_tmp.origin.x = CGRectGetMaxX(muteButton.frame);
            minusButton.frame = frame_tmp;
            
            frame_tmp = volumeLabel.frame;
            frame_tmp.origin.x = CGRectGetMaxX(minusButton.frame);
            volumeLabel.frame= frame_tmp;
            
            frame_tmp = plusButton.frame;
            frame_tmp.origin.x = CGRectGetMaxX(volumeLabel.frame);
            plusButton.frame = frame_tmp;
            
            muteForeground = [UIColor darkGrayColor];
            img = [UIImage imageNamed:@"button_metal_up"];
            [muteButton setBackgroundImage:img forState:UIControlStateNormal];
            [muteButton setBackgroundImage:img forState:UIControlStateHighlighted];
            img = [UIImage imageNamed:@"volume_slash"];
            img = [utils colorizeImage:img withColor:muteForeground];
            [muteButton setImage:img forState:UIControlStateNormal];
            
            img = [UIImage imageNamed:@"button_metal_down"];
            [minusButton setBackgroundImage:img forState:UIControlStateNormal];
            [minusButton setBackgroundImage:img forState:UIControlStateHighlighted];
            
            img = [UIImage imageNamed:@"button_metal_up"];
            [plusButton setBackgroundImage:img forState:UIControlStateNormal];
            [plusButton setBackgroundImage:img forState:UIControlStateHighlighted];
            
            // set final used width for this view
            frame_tmp = frame;
            frame_tmp.size.width = CGRectGetMaxX(plusButton.frame);
            self.frame = frame_tmp;
        }
        else {
            volumeView.hidden = YES;
            volumeLabel.hidden = YES;

            self.frame = CGRectMake(0, VOLUMEVIEW_OFFSET, [self currentScreenBoundsDependOnOrientation].size.width, VOLUMESLIDER_HEIGHT);
            
            frame_tmp = muteButton.frame;
            frame_tmp.origin.x = VOLUMEICON_PADDING;
            muteButton.frame = frame_tmp;
            
            frame_tmp = minusButton.frame;
            frame_tmp.origin.x = CGRectGetMaxX(muteButton.frame) + VOLUMEICON_PADDING;
            minusButton.frame = frame_tmp;
            
            frame_tmp = volumeSlider.frame;
            frame_tmp.origin.x = CGRectGetMaxX(minusButton.frame);
            frame_tmp.size.width = self.frame.size.width - frame_tmp.origin.x - ANCHORRIGHTPEEK - 3*VOLUMEICON_PADDING - volumeLabel.frame.size.width;
            volumeSlider.frame = frame_tmp;
            
            frame_tmp = plusButton.frame;
            frame_tmp.origin.x = CGRectGetMaxX(volumeSlider.frame) + VOLUMEICON_PADDING;
            plusButton.frame = frame_tmp;
            
            muteForeground = [UIColor blackColor];
            img = [UIImage imageNamed:@"button_metal_up"];
            img = [utils colorizeImage:img withColor:[UIColor darkGrayColor]];
            [muteButton setBackgroundImage:img forState:UIControlStateNormal];
            [muteButton setBackgroundImage:img forState:UIControlStateHighlighted];
            img = [UIImage imageNamed:@"volume_slash"];
            img = [utils colorizeImage:img withColor:muteForeground];
            [muteButton setImage:img forState:UIControlStateNormal];
            
            img = [UIImage imageNamed:@"volume_1"];
            img = [utils colorizeImage:img withColor:[UIColor grayColor]];
            [minusButton setImage:img forState:UIControlStateNormal];
            [minusButton setImage:img forState:UIControlStateHighlighted];
            [minusButton setBackgroundImage:nil forState:UIControlStateNormal];
            [minusButton setBackgroundImage:nil forState:UIControlStateHighlighted];
            [minusButton setTitle:nil forState:UIControlStateNormal];
            [minusButton setTitle:nil forState:UIControlStateHighlighted];
            
            img = [UIImage imageNamed:@"volume_3"];
            img = [utils colorizeImage:img withColor:[UIColor grayColor]];
            [plusButton setImage:img forState:UIControlStateNormal];
            [plusButton setImage:img forState:UIControlStateHighlighted];
            [plusButton setBackgroundImage:nil forState:UIControlStateNormal];
            [plusButton setBackgroundImage:nil forState:UIControlStateHighlighted];
            [plusButton setTitle:nil forState:UIControlStateNormal];
            [plusButton setTitle:nil forState:UIControlStateHighlighted];
        }
        [self checkMuteServer];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleApplicationOnVolumeChanged:)
                                                     name: @"Application.OnVolumeChanged"
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleServerStatusChanged:)
                                                     name: @"TcpJSONRPCChangeServerStatus"
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleEnterForeground:)
                                                     name: @"UIApplicationWillEnterForegroundNotification"
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleDidEnterBackground:)
                                                     name: @"UIApplicationDidEnterBackgroundNotification"
                                                   object: nil];
    }
    return self;
}

-(CGRect)currentScreenBoundsDependOnOrientation {
    return UIScreen.mainScreen.bounds;
}

-(void)handleServerStatusChanged:(NSNotification *)sender{
    volumeLabel.text = [NSString stringWithFormat:@"%d", [AppDelegate instance].serverVolume];
    volumeSlider.value = [AppDelegate instance].serverVolume;
    [self checkMuteServer];
}

-(void)handleApplicationOnVolumeChanged:(NSNotification *)sender{
    if (holdVolumeTimer == nil) {
        [AppDelegate instance].serverVolume = [[sender userInfo][@"params"][@"data"][@"volume"] intValue];
        [self handleServerStatusChanged:nil];
    }
}

- (void) handleDidEnterBackground: (NSNotification*) sender{
    [self stopTimer];
}

- (void) handleEnterForeground: (NSNotification*) sender{
    [self startTimer];
}

-(void)changeServerVolume:(id)sender{
    [[Utilities getJsonRPC]
     callMethod:@"Application.SetVolume" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:(int)volumeSlider.value], @"volume", nil]];
    if ([sender tag] == 10){
        [self startTimer];
    }
}

-(void)startTimer{
    volumeLabel.text = [NSString stringWithFormat:@"%d", [AppDelegate instance].serverVolume];
    volumeSlider.value = [AppDelegate instance].serverVolume;
    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(volumeInfo) userInfo:nil repeats:YES];
}

-(void)stopTimer{
    if (self.timer!=nil){
        [self.timer invalidate];
        self.timer=nil;
    }
}

-(void)volumeInfo{
    if ([AppDelegate instance].serverTCPConnectionOpen == YES) {
        return;
    }
    if ([AppDelegate instance].serverVolume > -1){
        volumeLabel.text = [NSString stringWithFormat:@"%d", [AppDelegate instance].serverVolume];
        volumeSlider.value = [AppDelegate instance].serverVolume;
    }
    else{
        volumeLabel.text = @"0";
        volumeSlider.value = 0;
    }
}

-(IBAction)slideVolume:(id)sender{
    volumeSlider.value = (int)volumeSlider.value;
    [AppDelegate instance].serverVolume = (int)volumeSlider.value;
    volumeLabel.text = [NSString  stringWithFormat:@"%.0f", volumeSlider.value];
}

-(IBAction)toggleMute:(id)sender {
    [self handleMute:!isMuted];
    [self changeMuteServer];
}

-(void)handleMute:(BOOL)mute {
    Utilities *utils = [[Utilities alloc] init];
    isMuted = mute;
    UIColor *buttonColor = isMuted ? [UIColor systemRedColor] : muteForeground;
    UIColor *sliderColor = isMuted ? [UIColor darkGrayColor] : SLIDER_DEFAULT_COLOR;

    UIImage *img = [UIImage imageNamed:@"volume_slash"];
    img = [utils colorizeImage:img withColor:buttonColor];
    [muteButton setImage:img forState:UIControlStateNormal];
    
    img = [UIImage imageNamed:@"pgbar_thumb_iOS7"];
    img = [utils colorizeImage:img withColor:sliderColor];
    [volumeSlider setThumbImage:img forState:UIControlStateNormal];
    [volumeSlider setMinimumTrackTintColor:sliderColor];
    [volumeSlider setUserInteractionEnabled:!isMuted];
}

-(void)changeMuteServer {
    [[Utilities getJsonRPC]
     callMethod:@"Application.SetMute"
     withParameters:@{@"mute": @"toggle"}];
}

-(void)checkMuteServer {
    [[Utilities getJsonRPC]
     callMethod:@"Application.GetProperties"
     withParameters:@{@"properties": @[@"muted"]}
     withTimeout: SERVER_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             isMuted = [methodResult[@"muted"] boolValue];
             [self handleMute:isMuted];
         }
    }];
}

NSInteger action;

-(IBAction)holdVolume:(id)sender{
    [self stopTimer];
    action = [sender tag];
    [self changeVolume];
    self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(changeVolume) userInfo:nil repeats:YES];
}

-(IBAction)stopVolume:(id)sender{
    if (self.holdVolumeTimer!=nil){
        [self.holdVolumeTimer invalidate];
        self.holdVolumeTimer=nil;
    }
    action = 0;
    [self startTimer];
}

-(void)changeVolume{
    if (self.holdVolumeTimer.timeInterval == 0.5){
        [self.holdVolumeTimer invalidate];
        self.holdVolumeTimer=nil;
        self.holdVolumeTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(changeVolume) userInfo:nil repeats:YES];        
    }
    if (action==1){ // Volume Raise
       volumeSlider.value = (int)volumeSlider.value + 2;
        
    }
    else if (action==2) { // Volume Lower
        volumeSlider.value = (int)volumeSlider.value - 2;

    }
    else { // Volume in 2-step resolution
        volumeSlider.value= ((int)volumeSlider.value / 2) * 2;
    }
    [AppDelegate instance].serverVolume = volumeSlider.value;
    volumeLabel.text=[NSString  stringWithFormat:@"%.0f", volumeSlider.value];
    [self changeServerVolume:nil];
    if (isMuted) {
        [self toggleMute:nil];
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self stopTimer];
}

@end
