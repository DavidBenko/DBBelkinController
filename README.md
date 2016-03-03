# DBBelkinController
Control Belkin WeMo devices easily using the beta Belkin WeMo SDK. 

## Setup
Add the Beta Belkin WeMo SDK to your project. 
> **Note:** You will need to get this directly from Belkin, the one on their website does not work correctly. I am not authorized to redristribute it, as it is beta software. You can contact the Belkin WeMo team here: Belkin.wemo.SDK@belkin.com

Add the following to your bridging header:
```objc
// Belkin WeMo SDK
#import "WeMoNetworkManager.h"
#import "WeMoDiscoveryManager.h"
#import "WeMoControlDevice.h"
#import "WeMoStateManager.h"
```

Add `DBBelkinController.swift` to your project. 

## Usage
Control a device by calling:
```swift
// Your device uuid
let udn = "uuid:Socket-1_0-1234567890"

// Your WeMo Command 
let state = WeMoDeviceOn

// Send Command
APBelkinController.sharedInstance().controlSwitch(udn, state: state)
```
> Right now, this class only supports the WeMo switch. Please open a pull request to add new device support. 

## License
MIT
