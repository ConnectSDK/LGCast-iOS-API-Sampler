# LG Cast SDK for iOS - Remote Camera
------------------

### Including LG Cast in your app using CocoaPods
Add `pod "ConnectSDK"` to your Podfile and run `pod install`. 
Open the workspace file and run your project.

#### Podfile example

	platform :ios, '12.0'
		
	def app_pods
	    pod 'ConnectSDK/Core', :git => 'https://github.com/ConnectSDK/Connect-SDK-iOS.git', :branch => 'master', :submodules => true
	end
		
	target 'RemoteCamera-Sampler' do
	  use_frameworks!
	  app_pods
		
	end


<br>


# Remote Camera
------------------
With Connect SDK integrated in the mobile app, it can display camera preview on the TV screen. This allows you to use your mobile device’s camera as a remote camera for the TV that does not have an internal or USB camera.

The remote camera function requires the camera permission and audio permission. The user must grant these permissions when the remote camera is first executed.
Register NSCameraUsageDescription and NSMicrophoneUsageDescription in Info.plist.

	<key>NSCameraUsageDescription</key>
	<string></string>
	<key>NSMicrophoneUsageDescription</key>
	<string></string>

<br>


How to Use Remote Camera
------------------
To use a remote camera, follow the steps below.
<br>

#### 1. Search Devices
Search for devices (TVs) connected to your home network. You can set the filter to only search for TVs that support the remote camera function.

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

#### 2. Select a TV
Select the TV to run the remote camera on by using the Picker. 

    _discoveryManager.devicePicker.delegate = self;
    [_discoveryManager.devicePicker showPicker:nil];   
<br>

Create a ViewController that displays the camera preview after the TV device is selected.
This viewController with camera preview should only support landscape mode.

	// MARK: DevicePickerDelegate
	- (void)devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device {
	    RemoteCameraViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"RemoteCameraViewController"];
	    [vc setDevice:device];
	    [self presentViewController:vc animated:YES completion:nil];
	}
<br>

After selecting a TV, get a RemoteCameraControl object to use the remote camera API.

    _remoteCameraControl = [_device remoteCameraControl];
    [_remoteCameraControl setRemoteCameraDelegate:self];
<br>    

#### 3. Start Remote Camera
Now you can run the remote camera. First, Connect with the selected TV device via `startRemoteCamera` of RemoteCameraControl. Then display the camera preview in the returned UIView.
Pairing is required when you connect to a TV for the first time.

    UIView *previewView = [_remoteCameraControl startRemoteCamera];
    [previewView setFrame:UIScreen.mainScreen.bounds];
    [self.view addSubview:previewView];
    [self.view sendSubviewToBack:previewView];
<br>

#### 4. Start Camera Playback
Select your iPhone camera on your TV. It will start sending and playing the camera stream. 
In this case, you can receive callbacks by designating a delegate.

	// MARK: RemoteCameraControlDelegate
	- (void)remoteCameraDidPlay {
	    NSLog(@"remoteCameraDidPlay");
	}
	
	- (void)remoteCameraDidChange:(RemoteCameraProperty)property {
	    NSLog(@"remoteCameraDidChange");
	}
<br>

#### 5. Change Camera Property
You can change camera properties such as brightness and AWB on the TV, and you can receive callbacks by designating a delegate.

	// MARK: RemoteCameraControlDelegate
	- (void)remoteCameraDidChange:(RemoteCameraProperty)property {
	    NSLog(@"remoteCameraDidChange");
	}
<br>


#### 6. Set the Microphone Mute State
If you change the microphone mute state, it must be transmitted. The app must maintain the current mute setting value.

	if (_remoteCameraControl != nil) {
		[_remoteCameraControl setMicMute:_isMuted];
	}
<br>


#### 7. Switch between Front and Back Cameras
When the direction of the camera is switched between front and rear, the camera direction is transmitted. The app must maintain the current camera direction value.

	if (_remoteCameraControl != nil) {
		[_remoteCameraControl setLensFacing:lensFacing];
	}
<br>

#### 8. Handle Runtime Errors
The following runtime error might occur while the remote camera is running.

 * When the network connection is terminated
 * When the TV is turned off
 * When the remote camera is terminated on the TV
 * When the mobile device’s notification terminates the remote camera
 * When other exceptions occurred

For these errors, it is necessary to receive the error in real-time through the listener and respond appropriately.

	- (void)remoteCameraErrorDidOccur:(RemoteCameraError)error {
	    NSLog(@"remoteCameraErrorDidOccur");
	    
	    if (_remoteCameraControl != nil) {
        	[_remoteCameraControl stopRemoteCamera];
        	_remoteCameraControl = nil;
       }
	}
<br>

When the app goes into the background state, the remote camera function does not work.
You must handle these situations appropriately.

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

#### 9. Stop Remote Camera
When you want to stop the remote camera, call `stopRemoteCamera`.

	if (_remoteCameraControl != nil) {
    	[_remoteCameraControl stopRemoteCamera];
    	_remoteCameraControl = nil;
	}
<br>

*Read this in other languages: [English](README.md), [한국어](README.ko.md)* 
