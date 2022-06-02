//
//  RemoteCameraViewController.m
//  LGCast-SDK-Sampler
//
//  Copyright (c) 2022 LG Electronics. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RemoteCameraViewController.h"

#import "RemoteCameraControl.h"

@interface RemoteCameraViewController ()

@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *changeCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *muteMicrophoneButton;

@end

@implementation RemoteCameraViewController {
    id<RemoteCameraControl> _remoteCameraControl;
    
    BOOL _isMuted;
    BOOL _isFacing;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeLeft] forKey:@"orientation"];
    
    _isMuted = NO;
    _isFacing = YES;
    
    [self drawMuteMicrophoneButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startRemoteCamera];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)didEnterBackground {
    [self stopRemoteCamera];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}

- (void)drawMuteMicrophoneButton {
    if (_isMuted) {
        [_muteMicrophoneButton setTitle:@"Unmute" forState:UIControlStateNormal];
    } else {
        [_muteMicrophoneButton setTitle:@"Mute" forState:UIControlStateNormal];
    }
}

- (IBAction)touchUpStopButton:(UIButton *)sender {
    [self stopRemoteCamera];
}

- (IBAction)touchUpChangeCameraButton:(UIButton *)sender {
    if (_remoteCameraControl != nil) {
        _isFacing = _isFacing ? NO : YES;
        int lensFacing = _isFacing ? RemoteCameraLensFacingFront : RemoteCameraLensFacingBack;
        [_remoteCameraControl setLensFacing:lensFacing];
    }
}

- (IBAction)touchUpMuteMicrophoneButton:(UIButton *)sender {
    if (_remoteCameraControl != nil) {
        _isMuted = _isMuted ? NO : YES;
        [_remoteCameraControl setMicMute:_isMuted];
    }
    
    [self drawMuteMicrophoneButton];
}

- (void)startRemoteCamera {
    _remoteCameraControl = [_device remoteCameraControl];
    
    if (_remoteCameraControl != nil) {
        [_remoteCameraControl setRemoteCameraDelegate:self];
        UIView *previewView = [_remoteCameraControl startRemoteCamera];
        [previewView setFrame:UIScreen.mainScreen.bounds];
        [self.view addSubview:previewView];
        [self.view sendSubviewToBack:previewView];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_stopButton setHidden:NO];
    });
}

- (void)stopRemoteCamera {
    if (_remoteCameraControl != nil) {
        [_remoteCameraControl stopRemoteCamera];
        _remoteCameraControl = nil;
    }
}

// MARK: RemoteCameraControlDelegate
- (void)remoteCameraDidPair {
    NSLog(@"remoteCameraDidPair");
}

- (void)remoteCameraDidStart:(BOOL)result {
    NSLog(@"remoteCameraDidStart");
}

- (void)remoteCameraDidStop:(BOOL)result {
    NSLog(@"remoteCameraDidStop");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)remoteCameraDidPlay {
    NSLog(@"remoteCameraDidPlay");
}

- (void)remoteCameraDidChange:(RemoteCameraProperty)property {
    NSLog(@"remoteCameraDidChange");
}

- (void)remoteCameraErrorDidOccur:(RemoteCameraError)error {
    NSLog(@"remoteCameraErrorDidOccur");
    
    [self stopRemoteCamera];
}

@end
