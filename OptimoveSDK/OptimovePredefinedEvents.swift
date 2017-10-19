//
//  OptimovePredefinedEvents.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 08/10/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import AdSupport



struct SetAdvertisingId : OptimoveEvent {
    var name: String
    {
        return Keys.Configuration.setAdvertisingId.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.advertisingId.rawValue   : ASIdentifierManager.shared().advertisingIdentifier.uuidString,
                Keys.Configuration.deviceId.rawValue        : UIDevice.current.identifierForVendor!.uuidString,
                Keys.Configuration.appNs.rawValue           : Bundle.main.bundleIdentifier!]}
}

//struct StitchEvent: OptimoveEvent {
//    var name: String { return Keys.Configuration.stitchEvent.rawValue}
//
//    var paramaeters: [String : Any] { return [Keys.Configuration.sourcePublicCustomerId.rawValue: UserInSession.shared.customerID,
//                                              Keys.Configuration.sourceVisitorId.rawValue: UserInSession.shared.visitorID!,
//
//        ]}
//
//}

struct NotificationDelivered: OptimoveEvent {
    
    let campaignId: Int
    let actionSerial: Int
    let templateId: Int
    let engagementId:Int
    let campaignType: Int
    
    var name: String
    {
        return Keys.Configuration.notificationDelivered.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.timestamp.rawValue   : Date().timeIntervalSince1970,
                Keys.Configuration.appNs.rawValue       : Bundle.main.bundleIdentifier!,
                Keys.Configuration.campignId.rawValue   : campaignId,
                Keys.Configuration.actionSerial.rawValue: actionSerial,
                Keys.Configuration.templateId.rawValue  : templateId,
                Keys.Configuration.engagementId.rawValue: engagementId,
                Keys.Configuration.campaignType.rawValue:campaignType]
    }
}

struct NotificationOpened : OptimoveEvent
{
    let campaignId: Int
    let actionSerial: Int
    let templateId: Int
    let engagementId:Int
    let campaignType: Int
    
    var name: String
    {
        return Keys.Configuration.notificationOpened.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.timestamp.rawValue   : Date().timeIntervalSince1970,
                Keys.Configuration.appNs.rawValue       : Bundle.main.bundleIdentifier!,
                Keys.Configuration.campignId.rawValue   : campaignId,
                Keys.Configuration.actionSerial.rawValue: actionSerial,
                Keys.Configuration.templateId.rawValue  : templateId,
                Keys.Configuration.engagementId.rawValue: engagementId,
                Keys.Configuration.campaignType.rawValue:campaignType]
    }
    
    
}

struct NotificationDismissed : OptimoveEvent {
    
    let campaignId: Int
    let actionSerial: Int
    let templateId: Int
    let engagementId:Int
    let campaignType: Int
    
    var name: String
    {
        return Keys.Configuration.notificationDismissed.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.timestamp.rawValue   : Date().timeIntervalSince1970,
                Keys.Configuration.appNs.rawValue       : Bundle.main.bundleIdentifier!,
                Keys.Configuration.campignId.rawValue   : campaignId,
                Keys.Configuration.actionSerial.rawValue: actionSerial,
                Keys.Configuration.templateId.rawValue  : templateId,
                Keys.Configuration.engagementId.rawValue: engagementId,
                Keys.Configuration.campaignType.rawValue:campaignType]
    }
}

struct BeforeSetUserId: OptimoveEvent {
    var name: String
    {
        return Keys.Configuration.beforeSetUserId.rawValue
    }
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.originalVisitorId.rawValue   : UserInSession.shared.visitorID!,
                Keys.Configuration.userId.rawValue              : UserInSession.shared.customerID!]
    }
}

struct OptipushOptIn: OptimoveEvent
{
    var name: String
    {
        return Keys.Configuration.optipushOptIn.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.timestamp.rawValue   : Date().timeIntervalSince1970,
                Keys.Configuration.appNs.rawValue       : Bundle.main.bundleIdentifier!]
    }
}

struct OptipushOptOut: OptimoveEvent
{
    var name: String
    {
        return Keys.Configuration.optipushOptOut.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.timestamp.rawValue   : Date().timeIntervalSince1970,
                Keys.Configuration.appNs.rawValue       : Bundle.main.bundleIdentifier!]
    }
}

struct AfterSetUserId: OptimoveEvent {
    var name: String
    {
        return Keys.Configuration.afterSetUserId.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.originalVisitorId.rawValue   : UserInSession.shared.visitorID!,
                Keys.Configuration.userId.rawValue              : UserInSession.shared.customerID!]
    }
}

struct SetUserAgent: OptimoveEvent {
    var name: String {return Keys.Configuration.setUserAgent.rawValue}
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.userAgentHeader.rawValue: UserInSession.shared.userAgentHeader]
    }
}


