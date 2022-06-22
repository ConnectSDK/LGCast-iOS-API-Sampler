//
//  ScreenMirroringViewController.m
//  ScreenMirroring-Sampler
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

#import "ScreenMirroringViewController.h"

#import "WebOSTVService.h"
#import "CapabilityFilter.h"
#import "DiscoveryManager.h"
#import "SSDPDiscoveryProvider.h"

#import "ScreenMirroringControl.h"

@interface ScreenMirroringViewController ()

@property (weak, nonatomic) IBOutlet UIView *rpPickerView;

@end

NSString *kConnectableDeviceIpAddressKey = @"ConnectableDeviceIpAddressKey";

@implementation ScreenMirroringViewController {
    DiscoveryManager *_discoveryManager;
    ConnectableDevice *_device;
    BOOL _isDiscoveringTV;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self drawBroadcastPickerView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startDiscoveryTV];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self stopDiscoveryTV];
}

- (void)drawBroadcastPickerView {
    if (@available(iOS 12.0, *)) {
        RPSystemBroadcastPickerView *rpPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:_rpPickerView.bounds];
        rpPickerView.preferredExtension = @"YOUR EXTENSION BUNDLE ID"; /* TODO:: CHANGE TO YOUR APP GROUP ID */
        rpPickerView.showsMicrophoneButton = NO;
        UIButton *button = rpPickerView.subviews.firstObject;
        button.imageView.tintColor = UIColor.whiteColor;
        [_rpPickerView addSubview:rpPickerView];
    } else {
        /* UNAVAILABLE */
    }
}

- (IBAction)touchUpTVDiscoveryButton:(UIButton *)sender {
    if (!_isDiscoveringTV) {
        [self startDiscoveryTV];
    }
    
    _discoveryManager.devicePicker.delegate = self;
    [_discoveryManager.devicePicker showPicker:nil];
}

- (void)startDiscoveryTV {
    _isDiscoveringTV = YES;

    if (_discoveryManager == nil) {
        _discoveryManager = [DiscoveryManager sharedManager];
    }
    
    NSArray *capabilities = @[ kScreenMirroringControlScreenMirroring ];

    CapabilityFilter *filter = [CapabilityFilter filterWithCapabilities:capabilities];
    [_discoveryManager setCapabilityFilters:@[filter]];
    [_discoveryManager setPairingLevel:DeviceServicePairingLevelOn];
    [_discoveryManager registerDeviceService:[WebOSTVService class] withDiscovery:[SSDPDiscoveryProvider class]];
    [_discoveryManager startDiscovery];
}

- (void)stopDiscoveryTV {
    if (!_isDiscoveringTV) return;
    
    _isDiscoveringTV = NO;
    [_discoveryManager stopDiscovery];
}

// MARK: DevicePickerDelegate

- (void)devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device {
    NSString *groupId = @"YOUR APP GROUP ID"; /* TODO:: CHANGE TO YOUR APP GROUP ID */
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupId];
    [sharedDefaults setObject:device.address forKey:kConnectableDeviceIpAddressKey];
    [sharedDefaults synchronize];
}

@end
