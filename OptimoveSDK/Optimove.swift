//
//  Optimove.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

public enum OptimoveError: Error
{
    case error
    case noNetwork
    case noPermissions
    case invalidEvent
    case mandatoryParameterMissing
}


/**
 The entry point of Optimove SDK.
 Initialize and configure Optimove using Optimove.sharedOptimove.configure.
 */
public class Optimove : OptimoveStateDelegate
{
    
    public var id: Int = -1
    
    //MARK: - Attributes
    var optiPush        : Optipush?
    var optitrack       : OptiTrack?
    
    var monitor         : MonitorOptimoveState
    var eventValidator  : EventValidator?
    
    
    
    public static let sharedInstance  = Optimove()
    
    public var hasDynamicLink: Bool
    {
        get
        {
            guard let optiPush = optiPush  else {return false}
            return optiPush.hasDynamicLink
        }
    }
    //MARK: - Constructor
    private init()
    {
        monitor = MonitorOptimoveState()
        monitor.register(stateDelegate: self)
    }
    
    
    // MARK: - API
    public func getDynamicLink(completionHandler: @escaping(DynamicLinkComponents?) -> Void)
    {
        optiPush?.getDynamicLink(completionHandler: completionHandler)
    }
    public func report(event:OptimoveEvent, completionHandler: ResultBlockWithError)
    {
        guard let eventValidator = eventValidator else
        {
            completionHandler(.error)
            return
        }
        eventValidator.validate(event: event)
        { [weak self](error) in
            if error == nil
            {
                guard let eventConfig = eventValidator.eventsConfigs[event.name] else { return } 
                self?.optitrack?.report(event: event,withConfigs: eventConfig)
                completionHandler(nil)
            }
            else
            {
                completionHandler(error)
            }
        }
    }
    
    public func set(userID: String)
    {
        guard !userID.isEmpty,
            !userID.contains("undefine"),
            !(userID == "null")
            else {return}
        
        if UserInSession.shared.isFirstConversion != false {
            if UserInSession.shared.isFirstConversion == nil {
                UserInSession.shared.isFirstConversion = true
            }
            UserInSession.shared.customerID = userID
            optitrack?.set(userID: userID)
            optiPush?.registrar?.register()
            UserInSession.shared.isFirstConversion = false
        }
    }
    
    public func handleRemoteNotificationArrived(userInfo: [AnyHashable : Any],
                                                fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        if optiPush == nil
        {
            return
        }
        optiPush?.handleNotification(userInfo: userInfo,
                                     completionHandler: completionHandler)
    }
    
    public func configure(info: OptimoveTenantInfo)
    
    {
        LogManager.reportToConsole("Start Configure Optimove SDK")
        UserInSession.shared.tenantToken = info.token
        UserInSession.shared.version = info.version
        UserInSession.shared.tenantID = info.id
        initializeOptimoveComponents(webAPIKey: info.apiKey, isClientFirebaseExist: info.hasFirebase)
        
        LogManager.reportToConsole("finish Optimove configuration")
    }
    
    public func register(stateDelegate: OptimoveStateDelegate)
    {
        monitor.register(stateDelegate: stateDelegate)
    }
    
    public func unregister(stateDelegate:OptimoveStateDelegate)
    {
        monitor.unregister(stateDelegate: stateDelegate)
    }
    
    public func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        optiPush?.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    //MARK: - Private Methods
    fileprivate func initializeOptimoveComponents(webAPIKey: String,  isClientFirebaseExist: Bool)
    {
        OptimoveComponentsInitializer(webAPIKey: webAPIKey, isClientFirebaseExist: isClientFirebaseExist, completionHandler:
            { [weak self]  (errors) in
                if !errors.isEmpty
                {
                    self?.monitor.initializationErrors = errors
                }
                else
                {
                    LogManager.reportSuccessToConsole("Optimove Components Successfully initialized ")
                }
        }).startInitialization()
    }
    
    //MARK: - Protocol Conformance
    public func didStartLoading() {
        
    }
    
    public func didBecomeActive() {
        LogManager.reportToConsole("report IDFA")
        report(event: SetAdvertisingId()) { (error) in
            //            if error == nil {
            //                print("Report event \(event) Succeeded ")
            //            }
            //            else{
            //                print("Report event \(event) Failed with error: \(error!)")
            //            }
        }
    }
    
    public func didBecomeInvalid(withErrors errors: [OptimoveError]) {
        
    }
    
}


