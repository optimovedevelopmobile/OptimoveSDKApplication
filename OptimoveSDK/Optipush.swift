
//  Optipush.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import Firebase
import UserNotifications

public struct DynamicLinkComponents
{
    public var path : String
    public var query: String
}

final class Optipush: NSObject
{
    //MARK: - Variables
    let clientHasFirebase: Bool
    let webAPIKey: String
    var registrar: Registrar?
    
    var shortUrl :URL?
    
    var hasDynamicLink:Bool
    {
        return shortUrl != nil
    }
    
    //MARK: - Constructor
    private init(webAPIKey: String, clientHasFirebase:Bool)
    {
        self.clientHasFirebase = clientHasFirebase
        self.webAPIKey = webAPIKey
        super.init()
    }
    
    //MARK: Static Methods
    static func newIntsance(from json: [String: Any],
                            webAPIKey: String,
                            clientHasFirebase:Bool,
                            initializationDelegate: ComponentInitializationDelegate) -> Optipush?
    {
        LogManager.reportToConsole("Initialize OptiPush")
        guard let mobileConfig = json[Keys.Configuration.mobile.rawValue] as? [String: Any],
            let optipushConfig = mobileConfig[Keys.Configuration.optipushMetaData.rawValue] as? [String: Any],
            let optipushMetaData = Parser.parseOptipushMetaData(from: optipushConfig),
            let firebaseConfig = mobileConfig[Keys.Configuration.firebaseProjectKeys.rawValue] as? [String: Any],
            let firebaseMetaData = Parser.parseFirebaseKeys(from: firebaseConfig)
            
            else
        {
            LogManager.reportFailureToConsole("Failed to parse optipush metadata")
            initializationDelegate.didFailInitialization(of: .optiPush, rootCause: .error)
            return nil
        }
        
        let optipush = Optipush(webAPIKey: webAPIKey, clientHasFirebase: clientHasFirebase)
        
        DispatchQueue.global(qos: .utility).async
            {
                optipush.registrar = Registrar(registrationEndPoint: optipushMetaData.registrationServiceRegistrationEndPoint,
                                               reportEndPoint: optipushMetaData.registrationServiceOtherEndPoint)
                optipush.setupFirebase(from: firebaseMetaData)
                optipush.setupNotification()
                optipush.enableUserNotification()
                initializationDelegate.didFinishInitialization(of: .optiPush)
        }
        LogManager.reportSuccessToConsole("OptiPush initialization succeed")
        return optipush
    }
    
    //MARK: - Private Methods
    
    private func setupNotification()
    {
        UNUserNotificationCenter.current().delegate = self
        DispatchQueue.main.async
            {
                UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    private func setupFirebase(from firebaMetaData: FirebaseMetaData)
    {
        DispatchQueue.main.async
            {
                
                if let secondaryOptions = self.generateOptimoveSecondaryOptions(from: firebaMetaData) {
                    if !self.clientHasFirebase
                    {
                        FirebaseApp.configure(options: secondaryOptions)
                    }
                    else
                    {
                        FirebaseApp.configure(name: "appController", options: secondaryOptions)
                        
                    }
                }
                
                FirebaseApp.configure(name: "sdkController", options: self.generateFirebaseMasterOptionsKeys())
        }
        Messaging.messaging().delegate = self
    }
    
     func generateOptimoveSecondaryOptions(from firebaseKeys: FirebaseMetaData) -> FirebaseOptions?
    {
        guard let appId = firebaseKeys.appId,
            let dbUrl = firebaseKeys.dbUrl,
            let senderId = firebaseKeys.senderId,
            let storageBucket = firebaseKeys.storageBucket,
            let projectId = firebaseKeys.projectId
            else { return nil }
        let appControllerOptions = FirebaseOptions.init(googleAppID: appId,
                                                        gcmSenderID: senderId)
        appControllerOptions.bundleID               = Bundle.main.bundleIdentifier!
        appControllerOptions.apiKey                 = webAPIKey
        appControllerOptions.databaseURL            = dbUrl
        appControllerOptions.storageBucket          = storageBucket
        appControllerOptions.deepLinkURLScheme      = appControllerOptions.bundleID
        appControllerOptions.projectID              = projectId
        appControllerOptions.clientID               = "gibrish-firebase"
        
        return appControllerOptions
    }
    
    func generateFirebaseMasterOptionsKeys() -> FirebaseOptions
    {
        let sdkMasterControllerOptions = FirebaseOptions.init(googleAppID: "1:628693349480:ios:c6eb1455c1b8d767", gcmSenderID: "628693349480")
        sdkMasterControllerOptions.bundleID = "com.optimove.sdk.master.ios"
        sdkMasterControllerOptions.apiKey = "AIzaSyDVSSZ4a-8ncUCoczGA-hbxz6j8xmrHZ7c"
        //secondaryOptions.clientID = "27992087142-ola6qe637ulk8780vl8mo5vogegkm23n.apps.googleusercontent.com" TODO!!!
        sdkMasterControllerOptions.databaseURL = "https://mobilesdk-master-dev.firebaseio.com"
        sdkMasterControllerOptions.storageBucket = "mobilesdk-master-dev.appspot.com"
        sdkMasterControllerOptions.projectID = "mobilesdk-master-dev"
        return sdkMasterControllerOptions
    }
    
    private func enableUserNotification()
    {
        LogManager.reportToConsole("Ask for user permission to present notifications")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
        { [weak self](granted, error) in
            if granted
            {
                LogManager.reportSuccessToConsole("Notification authorized by user")
                
                guard let isOptIn = UserInSession.shared.isOptIn
                    else { //Opt in on first launch
                        UserInSession.shared.isOptIn = true
                        return
                }
                if !isOptIn
                {
                    self?.registrar?.optIn()
                }
            }
            else
            {
                guard let isOptIn = UserInSession.shared.isOptIn else
                {
                    if  let hasRegisterJsonFile = UserInSession.shared.hasRegisterJsonFile
                    {
                        if !hasRegisterJsonFile
                        {
                            self?.registrar?.optOut()
                        }
                    }
                    return
                }
                LogManager.reportFailureToConsole("Notification unauthorized by user")
                if isOptIn
                {
                    self?.registrar?.optOut()
                }
            }
        }
    }
    
    private func configureUserNotifications()
    {
        let dismissAction = UNNotificationAction(identifier: "dismiss",
                                                 title: "Dismiss",
                                                 options: [])
        let category = UNNotificationCategory(identifier: "dismiss",
                                              actions: [dismissAction],
                                              intentIdentifiers: [],
                                              options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    //TODO: initialize sdk controller options
    
    //MARK: - Internal methods
    func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func getDynamicLink(completionHandler:@escaping (DynamicLinkComponents?) -> Void)
    {
        guard let dynamicLinks = DynamicLinks.dynamicLinks(),
            let shortUrl = shortUrl
            else
        {
            completionHandler(nil)
            return
        }
        dynamicLinks.handleUniversalLink(shortUrl)
        { (deepLink, error) in
            
            guard let path = deepLink?.url?.lastPathComponent,
                let query = deepLink?.url?.query else {
                    completionHandler(nil)
                    return}
            completionHandler(DynamicLinkComponents(path: path, query: query))
        }
    }
    
    //MARK: - Public API
    public func handleNotification(userInfo:[AnyHashable : Any],
                                   completionHandler:(UIBackgroundFetchResult) -> Void)
    {
        let content = UNMutableNotificationContent()
        content.title = userInfo[NotificationKeys.title.rawValue] as? String ?? Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        content.body = userInfo[NotificationKeys.body.rawValue] as? String ?? ""
        content.categoryIdentifier = userInfo[NotificationKeys.category.rawValue] as? String ?? ""
        content.userInfo[NotificationKeys.dynamicLink.rawValue] = userInfo[NotificationKeys.dynamicLink.rawValue] as? String ?? ""
        
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
        let request = UNNotificationRequest(identifier: "1",
                                            content: content,
                                            trigger: trigger)
        configureUserNotifications()
        UNUserNotificationCenter.current().add(request,withCompletionHandler: nil)
        completionHandler(.newData)
    }
}

extension Optipush:MessagingDelegate
{
    func messaging(_ messaging: Messaging,
                   didRefreshRegistrationToken fcmToken: String)
    {
        LogManager.reportToConsole("Enter to didRefreshRegistrationToken")
        LogManager.reportToConsole("fcmToken: \(fcmToken)")
        
        guard let oldFCMToken = UserInSession.shared.fcmToken
            else
        {
            LogManager.reportToConsole("Client receive a token for the first time")
            UserInSession.shared.fcmToken = fcmToken
            registrar?.register()
            return
        }
        
        if (fcmToken != oldFCMToken)
        {
            registrar?.unregister(didComplete: {
                UserInSession.shared.fcmToken = fcmToken
                self.registrar?.register()
            })
            
        }
    }
    
    func messaging(_ messaging: Messaging,
                   didReceive remoteMessage: MessagingRemoteMessage)
    {
        LogManager.reportToConsole("Enter to didReceive remoteMessage")
    }
}

extension Optipush:UNUserNotificationCenterDelegate
{
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
        LogManager.reportToConsole("User react to notification")
        LogManager.reportToConsole("Action = \(response.actionIdentifier)")
        
        if response.actionIdentifier == UNNotificationDismissActionIdentifier
        {
            //TODO: Send dismiss event to optitrack
        }
        else if response.actionIdentifier == UNNotificationDefaultActionIdentifier
        {
            //TODO: Handle Dynamic link if exist
            guard let dynamicLink =  response.notification.request.content.userInfo["dynamic_link"] as? String
                
                else { return }
            shortUrl = URL(string: dynamicLink )
        }
        //TODO: Send event to Optitrack
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler(.alert)
    }
}

