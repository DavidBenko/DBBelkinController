//
//  DBBelkinController.swift
//
//  Created by David Benko on 12/15/15.
//  Copyright © 2015 David Benko. All rights reserved.
//

private enum DBBelkinConstants: String {
    case BINARY_PUSH_NOTIFICATION_KEY = "Binary"
    case DEVICE_UDN = "Device UDN"
    case BINARY_STATE_OFF = "0"
    case BINARY_STATE_ON = "1"
    case BINARY_STATE_IDLE = "8"
    case SERVICETYPEEVENT = "urn:Belkin:service:basicevent:1"
    case ACT_GETBINARYSTATE = "GetBinaryState"
    case BINARY_STATE = "BinaryState"
}

class DBBelkinController : NSObject, WeMoDeviceDiscoveryDelegate {
    private static let instance = DBBelkinController()
    private let discoveryManager = WeMoDiscoveryManager.sharedWeMoDiscoveryManager()
    
    private(set) var devices: [WeMoControlDevice] = []
    
    static func sharedInstance() -> DBBelkinController{
        return DBBelkinController.instance
    }
    
    override init(){
        super.init()
        
        discoveryManager.deviceDiscoveryDelegate = self
        discoveryManager.discoverDevices(WeMoUpnpInterface)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "binaryStateChangeNotification:", name: wemoBinaryStateNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "insightBinaryStateChangeNotification:", name: wemoPushNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func statusForInsightDevice(device: WeMoControlDevice){
        var response: NSDictionary? = nil
        device.sendMessageToDeviceUsingService(DBBelkinConstants.SERVICETYPEEVENT.rawValue, action: DBBelkinConstants.ACT_GETBINARYSTATE.rawValue, arguments: nil, responseStateValue: nil, andResponseDict: &response)
        
        if response != nil {
            let binaryState: String = response![DBBelkinConstants.BINARY_STATE.rawValue] as! String
            
            if binaryState == DBBelkinConstants.BINARY_STATE_OFF.rawValue {
                device.state = WeMoDeviceOff
            }
            else if binaryState == DBBelkinConstants.BINARY_STATE_ON.rawValue || binaryState == DBBelkinConstants.BINARY_STATE_IDLE.rawValue {
                device.state = WeMoDeviceOn
            }
        }
    }
    
    // MARK: WeMo Control
    func controlSwitch(udn: String, state: WeMoDeviceState){
        for d in self.devices {
            if d.udn == udn {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    let result = d.setPluginStatus(state)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if result == WeMoSetDeviceStatusSuccess {
                            NSLog("Device %@:%@ State Changed Successfully",d.udn,d.friendlyName)
                        }
                        else {
                            NSLog("Error Changing Device %@:%@ State: %d", d.udn,d.friendlyName, result)
                        }
                    })
                })
                return
            }
        }
        
        NSLog("No Device with UDN: %@ Found",udn)
    }
    
    
    // MARK: WeMo Notification Handlers
    
    dynamic private func binaryStateChangeNotification(notification: NSNotification){
        let binaryNotification: NSDictionary = notification.object as! NSDictionary
        let binaryState: String = binaryNotification[DBBelkinConstants.BINARY_PUSH_NOTIFICATION_KEY.rawValue] as! String
        let udn: String = binaryNotification[DBBelkinConstants.DEVICE_UDN.rawValue] as! String
        
        // Set state on device
        for d in self.devices {
            if d.udn == udn {
                d.state = Int(binaryState)!
                NSLog("Device %@:%@ State Changed to %d",d.udn,d.friendlyName,d.state)
                break
            }
        }

    }
    
    dynamic private func insightBinaryStateChangeNotification(notification: NSNotification){
        let binaryNotification: NSDictionary = notification.object as! NSDictionary
        let binaryState: String = binaryNotification[DBBelkinConstants.BINARY_PUSH_NOTIFICATION_KEY.rawValue] as! String
        let udn: String = binaryNotification[DBBelkinConstants.DEVICE_UDN.rawValue] as! String
        
        // Set state on device
        for d in self.devices {
            if d.udn == udn {
                if binaryState == DBBelkinConstants.BINARY_STATE_OFF.rawValue {
                    d.state = WeMoDeviceOff;
                }
                else if binaryState == DBBelkinConstants.BINARY_STATE_ON.rawValue || binaryState == DBBelkinConstants.BINARY_STATE_IDLE.rawValue {
                    d.state = WeMoDeviceOn;
                }
                NSLog("Device %@:%@ State Changed to %d",d.udn,d.friendlyName,d.state)
                break
            }
        }
    }
    
    
    // MARK: WeMoDeviceDiscoveryDelegate Methods
    dynamic internal func discoveryManager(manager: WeMoDiscoveryManager!, didFoundDevice device: WeMoControlDevice!) {
        let lockQueue = dispatch_queue_create("com.anypresence.discoverwemodeviceslock", nil)
        dispatch_sync(lockQueue) {
            for d in self.devices {
                if device.udn == d.udn{
                    return
                }
            }
            
            if device.deviceType == 2 {
                //Insight devices have 3 states (ON/OFF/IDLE. So called a separate UPnP method to handle IDLE state. Insight device type is 2 as mentioned in DeviceConfigData.plist file.)
                self.statusForInsightDevice(device)
            }
            
            self.devices.append(device)
            NSLog("New Device = %@:%@",device.udn,device.friendlyName)
        }
    }
    
    dynamic internal func discoveryManager(manager: WeMoDiscoveryManager!, removeDeviceWithUdn udn: String!) {
        for(var i = 0; i < devices.count; i++){
            let d: WeMoControlDevice = devices[i]
            if d.udn == udn {
                NSLog("Remove Device = %@:%@",d.udn,d.friendlyName)
                devices.removeAtIndex(i)
                break
            }
        }
    }
    
    dynamic internal func discoveryManagerRemovedAllDevices(manager: WeMoDiscoveryManager!) {
        devices.removeAll()
    }
    
}
