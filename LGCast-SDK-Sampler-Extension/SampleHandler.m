//
//  SampleHandler.m
//  LGCast-SDK-Sampler-Extension
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

#import "SampleHandler.h"

#import "WebOSTVService.h"
#import "CapabilityFilter.h"
#import "DiscoveryManager.h"
#import "SSDPDiscoveryProvider.h"

#import "RemoteCameraControl.h"

NSString *kConnectableDeviceIpAddressKey = @"ConnectableDeviceIpAddressKey";

@implementation SampleHandler {
    DiscoveryManager *_discoveryManager;
    ConnectableDevice *_device;
    BOOL _isDiscoveringTV;
    
    NSString *_deviceAddress;
    
    id<ScreenMirroringControl> _screenMirroringControl;
}

- (instancetype)init {
    self = [super init];
    
    _discoveryManager = [DiscoveryManager sharedManager];
    
    NSString *groupId = @"AppGroupId"; /* TODO:: CHANGE TO YOUR APP GROUP ID */
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupId];
    _deviceAddress = [sharedDefaults stringForKey:kConnectableDeviceIpAddressKey];
    
    [self startDiscoveryTV];
    
    return self;
}

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    if (_screenMirroringControl != nil) {
        [_screenMirroringControl stopScreenMirroring];
    }
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    // Handle video sample buffer and audio sample buffer for app
    if (_screenMirroringControl != nil) {
        [_screenMirroringControl pushSampleBuffer:sampleBuffer with:sampleBufferType];
    }
}

// MARK: Private functions

- (void)startDiscoveryTV {
    _isDiscoveringTV = YES;

    if (_discoveryManager == nil) {
        _discoveryManager = [DiscoveryManager sharedManager];
    }
    
    NSArray *capabilities = @[
        kScreenMirroringControlScreenMirroring
    ];

    CapabilityFilter *filter = [CapabilityFilter filterWithCapabilities:capabilities];
    [_discoveryManager setCapabilityFilters:@[filter]];
    [_discoveryManager setPairingLevel:DeviceServicePairingLevelOn];
    [_discoveryManager registerDeviceService:[WebOSTVService class] withDiscovery:[SSDPDiscoveryProvider class]];
    [_discoveryManager startDiscovery];
    [_discoveryManager setDelegate:self];
}

- (void)stopDiscoveryTV {
    if (!_isDiscoveringTV) return;
    
    _isDiscoveringTV = NO;
    [_discoveryManager stopDiscovery];
}

// MARK: ScreenMirroringControlDelegate
- (void)screenMirroringDidStart:(BOOL)result {
    NSLog(@"screenMirroringDidStart %d", result);
}

- (void)screenMirroringDidStop:(BOOL)result {
    NSLog(@"screenMirroringDidStop %d", result);
}

- (void)screenMirroringErrorDidOccur:(ScreenMirroringError)error {
    NSLog(@"screenMirroringErrorDidOccur %d", error);
    [self finishBroadcastWithError:NULL];
}

// MARK: DiscoveryManagerDelegate

- (void)discoveryManager:(DiscoveryManager *)manager didFindDevice:(ConnectableDevice *)device {
    if (!_isDiscoveringTV || [device.address caseInsensitiveCompare:_deviceAddress] != NSOrderedSame) {
        return;
    }
    
    _device = device;
    _screenMirroringControl = [_device screenMirroringControl];
    
    if (_screenMirroringControl != nil) {
        [_screenMirroringControl startScreenMirroring];
        [_screenMirroringControl setScreenMirroringDelegate:self];
    }
    
    [self stopDiscoveryTV];
}

@end
