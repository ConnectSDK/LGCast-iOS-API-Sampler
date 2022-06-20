# LG Cast SDK for iOS - Screen Mirroring
------------------
### Including LG Cast in your app using CocoaPods
Add `pod "ConnectSDK"` to your Podfile and run `pod install`. 
Open the workspace file and run your project.
In case of Broadcast Upload Extension for Screen Mirroring, set the APPLICATION_EXTENSION_API_ONLY value to NO.

#### Podfile example

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

# Screen Mirroring
------------------
With Connect SDK integrated in the mobile app, it can cast the screen and sound into the TV screen. This allows you to extend the screen of a mobile app to a larger TV screen and share it with your family.

 * Screen mirroring: A way to dispay the entire app screen to the TV.
<br>


## ReplayKit - Broadcast Upload Extension
To capture iPhone screen, you need to implement Broadcast Upload Extension using Replay Kit.

**Reference** 
> [AppleDeveloper - ReplayKit](https://developer.apple.com/documentation/replaykit)
> 
> [WWDC2020 Capture and stream apps on the Mac with ReplayKit](https://developer.apple.com/videos/play/wwdc2020/10633)

<br>


How to Use Screen Mirroring
------------------
To use screen mirroring, follow these steps.
<br>


#### 1. Search Devices
Search for devices (TVs) connected to your home network. You can set the filter to only search for TVs that support the screen mirroring function. Since the search for TVs takes some time, it should be started as soon as the app is running.

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

#### 2. Select a TV
Select the TV to run the screen mirroring on by using the Picker. 

    _discoveryManager.devicePicker.delegate = self;
    [_discoveryManager.devicePicker showPicker:nil];   
<br>

Once the user has selected a device, the application needs to store that device identifier to find it. This sample code uses `NSUserDefaults` to store its device identifier.
   
    // MARK: DevicePickerDelegate
	 - (void)devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device {
		NSString *groupId = @"YOUR APP GROUP ID";	
    	NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupId];
     	[sharedDefaults setObject:device.address forKey:kConnectableDeviceIpAddressKey];
		[sharedDefaults synchronize];
	}
<br>

#### 3. Start Screen Mirroring
Now you can the screen mirroring. Start capturing the screen by creating an `RPSystemBroadcastPickerView`.

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

After the screen capture starts, you need to search once again with the information of selected TV device stored in the application.

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

If you find your TV again, get a ScreenMirroringControl object to use the screen mirroring API.
And then, you should immediately call the `startScreenMirroring` method.

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

#### 4. Broadcast Upload Extension Handling
You can get CMSampleBufferRef and RPSampleBufferType via SampleHandler's `processSampleBuffer:withType:`. It must be delivered to the screen mirroring API. 

	- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
	    // Handle video sample buffer and audio sample buffer for app
	    if (_screenMirroringControl != nil) {
	        [_screenMirroringControl pushSampleBuffer:sampleBuffer with:sampleBufferType];
	    }
	}
<br>

#### 5. Handle Runtime Errors

The following runtime errors might occur while the screen mirroring is running.

 * When the network connection is terminated
 * When the TV is turned off
 * When the screen mirroring is terminated on the TV
 * When the mobile device’s notification terminates the screen mirroring
 * When other exceptions occurred

For these errors, it is necessary to receive the error in real-time through the delegate and respond appropriately.
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

#### 6. Stop Screen Mirroring
When you want to stop mirroring, call `stopScreenMirroring` on `broadcastFinished` of SampleHandler.

	- (void)broadcastFinished {
	    // User has requested to finish the broadcast.
	    if (_screenMirroringControl != nil) {
	        [_screenMirroringControl stopScreenMirroring];
	}
<br>

*Read this in other languages: [English](README.md), [한국어](README.ko.md)* 
