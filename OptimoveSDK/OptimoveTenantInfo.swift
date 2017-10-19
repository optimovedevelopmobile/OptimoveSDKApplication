//
//  OptimoveTenantInfo.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 28/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

public struct OptimoveTenantInfo
{
    public var token       : String
    public var id          : Int
    public var version     : String
    public var apiKey      : String
    public var hasFirebase : Bool
    
    public init(token: String,
                id          : Int,
                version     : String,
                apiKey      : String,
                hasFirebase : Bool)
    {
        self.apiKey = apiKey
        self.hasFirebase = hasFirebase
        self.id = id
        self.token = token
        self.version = version
    }
}
