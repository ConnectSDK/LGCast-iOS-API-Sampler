# LG Cast SDK for iOS - 스크린 미러링
------------------
### CocoaPods 설정
Podfile에 `pod "ConnectSDK"`를 추가한 후 `pod install`을 실행하여 workspace를 생성합니다.
스크린 미러링 기능을 위한 Extension의 경우 APPLICATION_EXTENSION_API_ONLY 를 NO로 설정해주어야 합니다.

#### Podfile 예제

	platform :ios, '12.0'
	
	def app_pods
	    pod 'ConnectSDK/Core', :git => 'https://github.com/ConnectSDK/Connect-SDK-iOS.git', :branch => 'master', :submodules => true
	end
	
	target 'ScreenMirroring-Sampler' do
	  use_frameworks!
	  app_pods
	
	end
	
	target 'ScreenMirroring-Extension-Sampler' do
	  use_frameworks!
	  app_pods
	
	    post_install do |installer|
	      installer.pods_project.targets.each do |target|
	        target.build_configurations.each do |config|
	          config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
	        end
	      end
	    end
	end


<br>

# 스크린 미러링
------------------
LG Cast 스크린 미러링은 앱의 스크린과 오디오를 TV로 출력하는 기능을 제공합니다.
<br>


## ReplayKit - Broadcast Upload Extension
iPhone의 화면을 캡쳐하기 위해 ReplayKit을 사용하여 Broadcast Upload extension을 구현해야 한다.

**Reference** 
> [AppleDeveloper - ReplayKit](https://developer.apple.com/documentation/replaykit)
> 
> [WWDC2020 Capture and stream apps on the Mac with ReplayKit](https://developer.apple.com/videos/play/wwdc2020/10633)

<br>


스크린 미러링 구현 가이드
------------------
스크린 미러링 시작 절차는 다음과 같은 순서로 진행합니다.
<br>


#### 1. TV 검색
연결할 TV를 검색합니다. 검색시 스크린 미러링 기능을 지원하는 TV만 선별적으로 검색하기 위해 filter를 설정할 수 있습니다.

    if (_discoveryManager == nil) {
        _discoveryManager = [DiscoveryManager sharedManager];
    }
    
    NSArray *capabilities = @[ kScreenMirroringControlScreenMirroring ];

    CapabilityFilter *filter = [CapabilityFilter filterWithCapabilities:capabilities];
    [_discoveryManager setCapabilityFilters:@[filter]];
    [_discoveryManager setPairingLevel:DeviceServicePairingLevelOn];
    [_discoveryManager registerDeviceService:[WebOSTVService class] withDiscovery:[SSDPDiscoveryProvider class]];
    [_discoveryManager startDiscovery];
<br>

#### 2. TV 선택
검색된 TV 목록을 출력하고 스크린을 미러링할 TV를 선택합니다. 
TV 선택 이벤트를 전달받을 수 있도록 DevicePickerDelegate를 구현합니다.

    _discoveryManager.devicePicker.delegate = self;
    [_discoveryManager.devicePicker showPicker:nil];   
<br>

TV 디바이스 선택 후 Extension에서 선택된 TV를 다시 찾을 수 있도록 기기의 정보를 저장합니다.
저장하는 방법은 여러가지가 있을 수 있으나 예제에서는 NSUserDefaults를 사용합니다.
   
    // MARK: DevicePickerDelegate
	 - (void)devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device {
		NSString *groupId = @"YOUR APP GROUP ID";	
    	NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupId];
     	[sharedDefaults setObject:device.address forKey:kConnectableDeviceIpAddressKey];
		[sharedDefaults synchronize];
	}
<br>

#### 3. 스크린 미러링 시작
TV 디바이스를 선택했다면, RPSystemBroadcastPickerView를 생성하여 화면 캡쳐를 시작합니다.

	if (@available(iOS 12.0, *)) {
	        RPSystemBroadcastPickerView *rpPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:_rpPickerView.bounds];
        	rpPickerView.preferredExtension = @"YOUR EXTENSION BUNDLE ID";
	        rpPickerView.showsMicrophoneButton = NO;
	        UIButton *button = rpPickerView.subviews.firstObject;
	        button.imageView.tintColor = UIColor.whiteColor;
	        [_rpPickerView addSubview:rpPickerView];
	    } else {
        	/* UNAVAILABLE */
	    }
<br>

화면 캡쳐가 시작된 뒤, Extension의 SampleHandler에서 저장해 둔 TV 디바이스의 정보로 다시 한 번 검색합니다.
TV 디바이스 검색 이벤트를 전달받기 위해 DiscoveryManagerDelegate를 구현합니다.

	- (instancetype)init {
   		self = [super init];
    
	   _discoveryManager = [DiscoveryManager sharedManager];
    
		NSString *groupId = @"YOUR APP GROUP ID";
		NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupId];
		_deviceAddress = [sharedDefaults stringForKey:kConnectableDeviceIpAddressKey];
    
	    NSArray *capabilities = @[ kScreenMirroringControlScreenMirroring ];
	    CapabilityFilter *filter = [CapabilityFilter filterWithCapabilities:capabilities];
   		[_discoveryManager setCapabilityFilters:@[filter]];
	    [_discoveryManager setPairingLevel:DeviceServicePairingLevelOn];
    	[_discoveryManager registerDeviceService:[WebOSTVService class] withDiscovery:[SSDPDiscoveryProvider class]];
   		[_discoveryManager startDiscovery];
	    [_discoveryManager setDelegate:self];
    
   		return self;
	}
<br>

Screen Mirroring API 사용을 위한 ScreenMirroringControl 객체를 저장하여야 합니다.
스크린미러링 동작 중 발생하는 이벤트를 전달받기 위해 ScreenMirroringDelegate를 구현합니다.

	// MARK: DiscoveryManagerDelegate
	- (void)discoveryManager:(DiscoveryManager *)manager didFindDevice:(ConnectableDevice *)device {
	    if ([device.address caseInsensitiveCompare:_deviceAddress] != NSOrderedSame) {
	        return;
	    }
	    
	    _device = device;
	    _screenMirroringControl = [_device screenMirroringControl];
	    
	    if (_screenMirroringControl != nil) {
	        [_screenMirroringControl startScreenMirroring];
	        [_screenMirroringControl setScreenMirroringDelegate:self];
	    }
	    
	    [_discoveryManager stopDiscovery];
	}
<br>

위 절차가 완료되면 스크린 미러링을 실행할 수 있습니다. 처음으로 TV에 연결하는 경우 Paring이 필요합니다.

#### 4. Broadcast Upload Extension 구현
SampleHandler의 `processSampleBuffer:withType:` 을 통해 전달되는 CMSampleBufferRef 와 RPSampleBufferType를 ScreenMirroringControl의 `pushSampleBuffer:with:` 을 통해 그대로 전달합니다.

	- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
	    // Handle video sample buffer and audio sample buffer for app
	    if (_screenMirroringControl != nil) {
	        [_screenMirroringControl pushSampleBuffer:sampleBuffer with:sampleBufferType];
	    }
	}
<br>

#### 5. 예외 처리
스크린 미러링 실행 중 다음과 같은 런타임 에러가 발생할 수 있습니다.
	1) 네트워크 연결이 종료된 경우
	2) TV가 종료된 경우
	3) TV에서 Screen Mirroing이 종료된 경우
	4) 폰 Notification으로 미러링 기능을 종료한 경우
	5) 기타 예외상황 발생

이러한 에러에 대해서는 ScreenMirroringDelegate를 통해 전달받아 적절한 처리를 하여야 합니다.
<br>

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

<br>

#### 6. 스크린 미러링 종료
스크린 미러링을 종료하기 위해 SampleHandler의 `broadcastFinished`에서 `stopScreenMirroring`을 호출합니다.

	- (void)broadcastFinished {
	    // User has requested to finish the broadcast.
	    if (_screenMirroringControl != nil) {
	        [_screenMirroringControl stopScreenMirroring];
	}
<br>
