//
//  Registrar.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 11/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation



protocol RegistrationProtocol
{
    func register()
    func unregister(didComplete: @escaping ResultBlock)
}

protocol OptProtocol
{
    func optIn()
    func optOut()
}


class Registrar
{
    enum Category
    {
        case registration
        case opt
    }
    //MARK: - Internal Variables
    var registrationEndPoint: String
    var reportEndPoint: String
    
    //MARK: - Constructor
    init(registrationEndPoint: String, reportEndPoint: String)
    {
        self.registrationEndPoint   = registrationEndPoint
        self.reportEndPoint         = reportEndPoint
    }
    
    //MARK: - Internal Methods
    func retryFailedOperationsIfExist()
    {
        let isVisitor = UserInSession.shared.customerID == nil ? false : true
        let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        
        if UserInSession.shared.hasOptInOutJsonFile {
            
            let actionFile = "opt_in_out_data.json"
            let actionURL = appSupportDirectory.appendingPathComponent("OptimoveSDK/\(actionFile)")
            
            do {
                let json  = try Data.init(contentsOf: actionURL)
                optimoveRegistrationRequest(type: .opt, json: json, path: actionURL.path)
            }
            catch { return }
        }
        if let hasRegisterJsonFile = UserInSession.shared.hasRegisterJsonFile
        {
            if hasRegisterJsonFile
            {
                
                let actionFile = "register_data.json"
                let actionURL = appSupportDirectory.appendingPathComponent("OptimoveSDK/\(actionFile)")
                do {
                    let json  = try Data.init(contentsOf: actionURL)
                    
                    let path = isVisitor ? NetworkAPIPaths.pathForRegisterVisitor() : NetworkAPIPaths.pathForRegisterCustomer()
                    optimoveRegistrationRequest(type: .registration, json: json, path: path)
                }
                catch { return }
            }
        }
        if UserInSession.shared.hasUnregisterJsonFile {
            
            let actionFile = "register_data.json"
            let actionURL = appSupportDirectory.appendingPathComponent("OptimoveSDK/\(actionFile)")
            do {
                let json  = try Data.init(contentsOf: actionURL)
                
                let path = isVisitor ? NetworkAPIPaths.pathForUnregisterVisitor() : NetworkAPIPaths.pathForUnregisterCustomer()
                optimoveRegistrationRequest(type: .registration, json: json, path: path )
            }
            catch { return }
        }
    }
    //MARK: - Private Methods
    fileprivate func optInOutVisitor(state:State.Opt)
    {
        LogManager.reportToConsole("Visitor Opt InOut")
        if let json = JSONComposer.composeOptInOutVisitorJSON(forState: state)
        {
            optimoveRegistrationRequest(type:  .opt , json: json, path: NetworkAPIPaths.pathForOptInOutVisitor())
        }
    }
    
    fileprivate func optInOutCustomer(state:State.Opt)
    {
        LogManager.reportToConsole("Customr Opt InOut")
        if let json = JSONComposer.composeOptInOutCustomerJSON(forState: state)
        {
            optimoveRegistrationRequest(type: .opt, json: json, path: NetworkAPIPaths.pathForOptInOutCustomer())
        }
    }
    
    fileprivate func unRegisterCustomer(didComplete: @escaping ResultBlock)
    {
        LogManager.reportToConsole("Unregister customer to MBAAS")
        
        if let json = JSONComposer.composeUnregisterCustomerJSON()
        {
            optimoveRegistrationRequest(type: .registration, json: json, path: NetworkAPIPaths.pathForUnregisterCustomer(),didComplete: didComplete)
        }
    }
    
    fileprivate func registerCustomer()
    {
        LogManager.reportToConsole("Register customer to MBAAS")
        if let json = JSONComposer.composeRegisterCustomer()
        {
            optimoveRegistrationRequest(type: .registration, json: json, path: NetworkAPIPaths.pathForRegisterCustomer())
        }
    }
    
    fileprivate func registerVisitor()
    {
        LogManager.reportToConsole("Register visitor to MBAAS")
        
        if let json = JSONComposer.composeRegisterVisitor()
        {
            optimoveRegistrationRequest(type: .registration, json: json, path: NetworkAPIPaths.pathForRegisterVisitor())
        }
    }
    
    fileprivate func unregisterVisitor( didComplete:@escaping ResultBlock)
    {
        LogManager.reportToConsole("Unregister visitor to MBAAS")
        
        if let json = JSONComposer.composeUnregisterVisitor()
        {
            optimoveRegistrationRequest(type: .registration, json: json, path: NetworkAPIPaths.pathForUnregisterVisitor(),didComplete: didComplete)
        }
    }
    
    fileprivate func optimoveRegistrationRequest(type: Registrar.Category,
                                                 json:Data,
                                                 path: String,
                                                 didComplete: ResultBlock? = nil)
    {
        let endPoint = type == .registration ? registrationEndPoint : reportEndPoint
        if let url  = URL(string: endPoint + path)
        {
            var request = URLRequest(url: url)
            request.httpMethod = HttpMethod.post.rawValue
            request.httpBody = json
            request.setValue(MediaType.json.rawValue,
                             forHTTPHeaderField: HttpHeader.contentType.rawValue)
            
            LogManager.reportToConsole("Send request to \(endPoint+path)")
            LogManager.reportData(json)
            let task = URLSession.shared.dataTask(with: request, completionHandler:
            { (data, response, error) in
                if error != nil
                {
                    LogManager.reportError(error: error)
                    LogManager.reportToConsole("Storing \(path) in disk!!" )
                    storeJSONInFileSystem()
                }
                else
                {
                    markFileAsDone()
                    LogManager.reportData(data!)
                    didComplete?()
                }
            })
            task.resume()
        }
        
        func storeJSONInFileSystem()
        {
            LogManager.reportToConsole("Store file in disk")
            var actionFile = ""
            switch path {
            case NetworkAPIPaths.pathForRegisterCustomer():
                fallthrough
            case NetworkAPIPaths.pathForRegisterVisitor():
                UserInSession.shared.hasRegisterJsonFile = true
                actionFile = "register_data.json"
            case NetworkAPIPaths.pathForUnregisterVisitor():
                fallthrough
            case NetworkAPIPaths.pathForUnregisterCustomer():
                UserInSession.shared.hasUnregisterJsonFile = true
                actionFile = "unregister_data.json"
            case NetworkAPIPaths.pathForOptInOutVisitor():
                fallthrough
            case NetworkAPIPaths.pathForOptInOutCustomer():
                UserInSession.shared.hasOptInOutJsonFile = true
                actionFile = "opt_in_out_data.json"
                
            default:
                return
            }
            let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let actionURL = appSupportDirectory.appendingPathComponent("OptimoveSDK/\(actionFile)")
            let success =  FileManager.default.createFile(atPath: actionURL.path, contents: json, attributes: nil)
            LogManager.reportToConsole("Storing status is \(success)\n location: \(actionURL.path)")
        }
        
        func markFileAsDone()
        {
            var actionFile = ""
            switch path {
            case NetworkAPIPaths.pathForRegisterCustomer():
                fallthrough
            case NetworkAPIPaths.pathForRegisterVisitor():
                UserInSession.shared.hasRegisterJsonFile = false
                actionFile = "register_data.json"
            case NetworkAPIPaths.pathForUnregisterVisitor():
                fallthrough
            case NetworkAPIPaths.pathForUnregisterCustomer():
                UserInSession.shared.hasUnregisterJsonFile = false
                actionFile = "unregister_data.json"
            case NetworkAPIPaths.pathForOptInOutVisitor():
                fallthrough
            case NetworkAPIPaths.pathForOptInOutCustomer():
                UserInSession.shared.hasOptInOutJsonFile = false
                actionFile = "opt_in_out_data.json"
                
            default:
                return
            }
            let appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let actionURL = appSupportDirectory.appendingPathComponent("OptimoveSDK/\(actionFile)")
            if FileManager.default.fileExists(atPath: actionURL.path)
            {
                do {
                    try FileManager.default.removeItem(at: actionURL)
                    LogManager.reportSuccessToConsole("Deleting succeeded\n location: \(actionURL.path)")
                }
                catch {
                    LogManager.reportFailureToConsole("Deleting failed\n location: \(actionURL.path)")
                }
            }
        }
    }
}

extension Registrar: RegistrationProtocol
{
    func register()
    {
         CustomerID == nil ? registerVisitor() : registerCustomer()
    }
    
    func unregister(didComplete:@escaping ResultBlock)
    {
        CustomerID == nil ? unregisterVisitor(didComplete: didComplete) : unRegisterCustomer(didComplete: didComplete)
        
    }
}

extension Registrar : OptProtocol
{
    func optIn()
    {
        CustomerID == nil ? optInOutVisitor(state: .optIn) : optInOutCustomer(state: .optIn)
        UserInSession.shared.isOptIn = true
    }
    
    func optOut()
    {
        CustomerID == nil ? optInOutVisitor(state: .optOut) : optInOutCustomer(state: .optOut)
        UserInSession.shared.isOptIn = false
    }
}
