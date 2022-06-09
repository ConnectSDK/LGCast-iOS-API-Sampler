//
//  RemoteCameraTabViewController.m
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

#import "RemoteCameraTabViewController.h"
#import "RemoteCameraViewController.h"

#import "WebOSTVService.h"
#import "CapabilityFilter.h"
#import "DiscoveryManager.h"
#import "SSDPDiscoveryProvider.h"

#import "RemoteCameraControl.h"

@interface RemoteCameraTabViewController ()

@property (weak, nonatomic) IBOutlet UIButton *selectTVButton;

@end

@implementation RemoteCameraTabViewController {
    DiscoveryManager *_discoveryManager;
    ConnectableDevice *_device;
    BOOL _isDiscoveringTV;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startDiscoveryTV];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self stopDiscoveryTV];
}

- (IBAction)selectTV:(id)sender {
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
    
    NSArray *capabilities = @[ kRemoteCameraControlRemoteCamera ];

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
    RemoteCameraViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"RemoteCameraViewController"];
    [vc setDevice:device];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
