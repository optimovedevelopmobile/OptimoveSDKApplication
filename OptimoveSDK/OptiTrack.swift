//
//  Optitrack.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import PiwikTracker
import AdSupport

protocol ConversionProcol
{
    func didConvertToCustomer()
}
protocol TrackProtocol
{
    func report(event: OptimoveEvent,withConfigs config: EventConfig)
    func set(userID: String)
}

class OptiTrack
{
    //MARK: - Internal Variables
    var metaData: OptitrackMetaData
    
    //MARK: - Constructor
    private init(from metaData: OptitrackMetaData)
    {
        self.metaData = metaData
    }
    
    //MARK: - Private Methods
    private static func handleVisitorIDStore()
    {
//        if let visitorID = UserInSession.shared.visitorID
//        {
//            PiwikTracker.shared?.visitor.visitorId = visitorID
//        }
//        else
//        {
            UserInSession.shared.visitorID = PiwikTracker.shared?.visitorId
//        }
    }
    
    private static func updateCustomerID()
    {
        PiwikTracker.shared?.visitorId = UserInSession.shared.customerID
    }
    
    //MARK: - Internal Methods
    
    static func newIntsance(from json: [String: Any],
                            initializationDelegate: ComponentInitializationDelegate) -> OptiTrack?
    {
        LogManager.reportToConsole("Initialize OptiTrack")
        guard let optitrackConfig = json[Keys.Configuration.optitrackMetaData.rawValue] as? [String: Any],
            let optitrackMetaData = Parser.parseOptitrackMetadata(from: optitrackConfig)
            else
        {
            LogManager.reportFailureToConsole("Failed to parse optitrack metadata")
            initializationDelegate.didFailInitialization(of: .optiPush, rootCause: .error)
            return nil
        }
        let optitrack = OptiTrack(from: optitrackMetaData)
        
        
        
        if let url = URL.init(string: optitrack.metaData.optitrackEndpoint)
        {
            PiwikTracker.configureSharedInstance(withSiteID: String.init(optitrack.metaData.siteId), baseURL: url)
            
            self.handleVisitorIDStore()
            self.updateCustomerID()
            
            initializationDelegate.didFinishInitialization(of: .optiTrack)
        }
        LogManager.reportSuccessToConsole("OptiTrack initialization succeed")
        return optitrack
    }
}

extension OptiTrack: TrackProtocol
{
    func report(event: OptimoveEvent,withConfigs config: EventConfig)
    {
        guard config.supportedComponents[.optiTrack] == true,
            let tracker = PiwikTracker.shared else
        {
            LogManager.reportFailureToConsole("optiTrack component not supported")
            return
        }
        // TODO protect nil case
        var dimensionsIDs: [Int] = []
        
        
        dimensionsIDs.append(metaData.eventIdCustomDimensionId)
        tracker.set(value:String(config.id), forIndex: metaData.eventIdCustomDimensionId)
        dimensionsIDs.append(metaData.eventNameCustomDimensionId)
        tracker.set(value: event.name, forIndex: metaData.eventNameCustomDimensionId)
        
        
        for (name,value) in event.paramaeters
        {
            let optitrackDimensionID = config.params[name]!.optitrackDimensionID
            dimensionsIDs.append(optitrackDimensionID)
            tracker.set(value: "\(value)", forIndex: optitrackDimensionID)
        }
        
        tracker.track(eventWithCategory: metaData.eventCategoryName,
                      action: event.name,
                      name: nil,
                      number: nil)
        tracker.dispatch()//MARK: REMOVE On Production
        for index in dimensionsIDs
        {
            tracker.remove(dimensionAtIndex: index)
        }
    }
    
    func set(userID: String)
    {
        //TODO: Add Before set user ID event
       
        UserInSession.shared.customerID = userID
        Optimove.sharedInstance.report(event: BeforeSetUserId()) { (error) in
            guard error == nil else
            {
                LogManager.reportError(error: error)
                return
            }
            PiwikTracker.shared?.visitorId = userID
            Optimove.sharedInstance.report(event: AfterSetUserId(), completionHandler: { (error) in
                guard error == nil else
                {
                    LogManager.reportError(error: error)
                    return
                }
            })
        }
        //TODO: Add after set user id event
        PiwikTracker.shared?.dispatch() //MARK: REMOVE On Production
    }
    
}
