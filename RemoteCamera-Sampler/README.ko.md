# LG Cast SDK for iOS - 원격 카메라
------------------

### CocoaPods 설정
Podfile에 `pod "ConnectSDK"`를 추가한 후 `pod install`을 실행하여 workspace를 생성합니다.

#### Podfile 예제

	platform :ios, '12.0'
		
	def app_pods
	    pod 'ConnectSDK/Core', :git => 'https://github.com/ConnectSDK/Connect-SDK-iOS.git', :branch => 'master', :submodules => true
	end
		
	target 'RemoteCamera-Sampler' do
	  use_frameworks!
	  app_pods
		
	end


<br>


# 원격 카메라
------------------
LG Cast 원격 카메라는 핸드폰의 카메라 프리뷰 영상을 TV로 출력하는 기능을 제공합니다. 
이 기능을 이용하면 카메라가 없는 TV에서, 핸드폰의 카메라를 TV 카메라도 이용할 수 있습니다.

원력 카메라 기능은 카메라와 마이크에 대한 권한을 필요로 하며, 앱 실행 시 이에 대한 사용자 동의를 득하여야 합니다.
Info.plist에 NSCameraUsageDescription 및 NSMicrophoneUsageDescription 을 등록합니다.

	<key>NSCameraUsageDescription</key>
	<string></string>
	<key>NSMicrophoneUsageDescription</key>
	<string></string>

<br>


원격 카메라 구현 가이드
------------------

#### 1. TV 검색
홈네트워크에 연결된 TV를 검색합니다. 
검색시 원격 카메라 기능을 지원하는 TV만 선별적으로 검색하기 위해 filter를 설정할 수 있습니다.

    if (_discoveryManager == nil) {
        _discoveryManager = [DiscoveryManager sharedManager];
    }
    
    NSArray *capabilities = @[ kRemoteCameraControlRemoteCamera ];

    CapabilityFilter *filter = [CapabilityFilter filterWithCapabilities:capabilities];
    [_discoveryManager setCapabilityFilters:@[filter]];
    [_discoveryManager setPairingLevel:DeviceServicePairingLevelOn];
    [_discoveryManager registerDeviceService:[WebOSTVService class] withDiscovery:[SSDPDiscoveryProvider class]];
    [_discoveryManager startDiscovery];
<br>

#### 2. TV 선택
검색된 TV 목록을 출력하고 원격 카메라를 실행할 TV를 선택합니다. 
TV 선택 이벤트를 전달받을 수 있도록 DevicePickerDelegate를 구현합니다.

    _discoveryManager.devicePicker.delegate = self;
    [_discoveryManager.devicePicker showPicker:nil];   
<br>

TV 디바이스 선택 후 카메라 프리뷰를 보여줄 ViewController를 생성합니다.
카메라가 동작하는 ViewController는 가로 모드로만 동작하도록 강제해야 합니다.

	// MARK: DevicePickerDelegate
	- (void)devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device {
	    RemoteCameraViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"RemoteCameraViewController"];
	    [vc setDevice:device];
	    [self presentViewController:vc animated:YES completion:nil];
	}
<br>

원격 카메라 API 사용을 위한 RemoteCameraControl 객체를 얻어옵니다.
원격 카메라 동작 중 발생하는 이벤트를 전달받기 위해 RemoteCameraControlDelegate를 구현합니다.

    _remoteCameraControl = [_device remoteCameraControl];
    [_remoteCameraControl setRemoteCameraDelegate:self];
<br>    

#### 3. 원격 카메라 실행 및 프리뷰 시작
상기의 사전 작업이 완료되면 원격 카메라를 실행할 수 있습니다.
RemoteCameraControl의 `startRemoteCamera`를 통해 선택된 TV 디바이스와 연결하고 반환되는 UIView로 카메라 프리뷰를 보여줍니다.
처음으로 TV에 연결하는 경우 Paring이 필요합니다.

    UIView *previewView = [_remoteCameraControl startRemoteCamera];
    [previewView setFrame:UIScreen.mainScreen.bounds];
    [self.view addSubview:previewView];
    [self.view sendSubviewToBack:previewView];
<br>

#### 4. TV에서 카메라 선택 
TV에서 폰 카메라를 선택하면 카메라 스트림 전송 및 재생이 시작됩니다.
이 때, RemoteCameraControlDelegate의 `remoteCameraDidPlay` 를 통해 이벤트가 전달됩니다.

	// MARK: RemoteCameraControlDelegate
	- (void)remoteCameraDidPlay {
	    NSLog(@"remoteCameraDidPlay");
	}
	
	- (void)remoteCameraDidChange:(RemoteCameraProperty)property {
	    NSLog(@"remoteCameraDidChange");
	}
<br>

#### 5. 카메라 Property 변경
TV에서 밝기, AWB 등의 카메라 속성을 변경할 수 있습니다.
Property가 변경되는 경우 RemoteCameraControlDelegate의 `remoteCameraDidChange:` 를 통해 이벤트가 전달됩니다.

	// MARK: RemoteCameraControlDelegate
	- (void)remoteCameraDidChange:(RemoteCameraProperty)property {
	    NSLog(@"remoteCameraDidChange");
	}
<br>


#### 6. 마이크 음소거 변경
마이크 음소거 여부를 변경한 경우 음소거 여부를 전달하여야 합니다. 
앱에서는 현재 음소거 설정 값을 유지하여야 합니다.

	if (_remoteCameraControl != nil) {
		[_remoteCameraControl setMicMute:_isMuted];
	}
<br>


#### 7. 전/후 렌즈 변경하기
카메라 렌즈의 전/후 방향을 변경한 경우 카메라 방향을 전달하여야 합니다. 
앱에서는 현재 카메라 방향 값을 유지하여야 합니다.

	if (_remoteCameraControl != nil) {
		[_remoteCameraControl setLensFacing:lensFacing];
	}
<br>

#### 8. 예외 처리
원격 카메라가 실행된 후 다음과 같은 Run-Time error가 발생할 수 있습니다. 
이러한 에러에 대해서는 리스너를 등록하여 실시간으로 전달받아 적절한 처리를 하여야 합니다.

  1) 네트워크 연결이 종료된 경우
  2) TV가 종료된 경우
  3) TV에서 Screen Mirroing이 종료된 경우
  4) 폰 Notification으로 미러링 기능을 종료한 경우
  5) 기타 예외상황 발생


	- (void)remoteCameraErrorDidOccur:(RemoteCameraError)error {
	    NSLog(@"remoteCameraErrorDidOccur");
	    
	    if (_remoteCameraControl != nil) {
        	[_remoteCameraControl stopRemoteCamera];
        	_remoteCameraControl = nil;
      	    }
	}

앱이 Background 상태가 되면 원격 카메라 기능이 동작할 수 없기 때문에 이에 대해 처리해주어야 합니다.

	- (void)viewDidAppear:(BOOL)animated {
	    [super viewDidAppear:animated];
	    
	    ...
	    
	    [[NSNotificationCenter defaultCenter] addObserver:self
	                                             selector:@selector(didEnterBackground)
	                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
	
	- (void)didEnterBackground {
		if (_remoteCameraControl != nil) {
        		[_remoteCameraControl stopRemoteCamera];
	        	_remoteCameraControl = nil;
      		}
	}
	
	- (void)viewWillDisappear:(BOOL)animated {
	    [super viewWillDisappear:animated];
	
	    [[NSNotificationCenter defaultCenter] removeObserver:self
	                                                    name:UIApplicationDidEnterBackgroundNotification
	                                                  object:nil];
	}
<br>

#### 9. 원격 카메라 종료
사용자가 원격 카메라를 종료하는 경우 RemoteCameraControl의 `stopRemoteCamera` 를 호출합니다.

	if (_remoteCameraControl != nil) {
    	[_remoteCameraControl stopRemoteCamera];
    	_remoteCameraControl = nil;
	}
<br>
