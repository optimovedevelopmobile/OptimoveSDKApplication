//
//  Monitor.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 06/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation


public protocol OptimoveStateDelegate
{
    func didStartLoading()
    func didBecomeActive()
    func didBecomeInvalid(withErrors errors : [OptimoveError])
    
    var id: Int { get }
}

class MonitorOptimoveState
{
    //MARK: - Constructor
    init(componentsState: [Component:State.Component] = [.optiPush:.unknown,
                                                         .optiTrack:.unknown],
         sdkState :State.SDK       = .loading,
         stateDalegates: [Int : OptimoveStateDelegate]  = [:])
    {
        LogManager.reportToConsole("Initialize Monitor")
        self.componentsState = componentsState
        self.sdkState = sdkState
        self.stateDalegates = stateDalegates
        LogManager.reportToConsole("Finish initializing Monitor")
    }
    
    //MARK: - Private Variables
    private var componentsState : [Component:State.Component]
    private var sdkState: State.SDK
    {
        didSet
        {
            for (_,delegate) in stateDalegates
            {
                notifyDelegate(delegate)
            }
        }
    }
    private var stateDalegates: [Int : OptimoveStateDelegate]
    
    var initializationErrors: [OptimoveError]?
    {
        didSet
        {
            if initializationErrors?.isEmpty ?? true
            {
               sdkState = .inactive
            }
        }
    }
    
    //MARK: - Internal Methods
    func update(component: Component, state: State.Component)
    {
        componentsState.updateValue(state, forKey: component)
        updateSDKState()
    }
    
    func getState(of component:Component) -> State.Component?
    {
        return componentsState[component]
    }
    
    func register(stateDelegate: OptimoveStateDelegate)
    {
        notifyDelegate(stateDelegate)
        stateDalegates[stateDelegate.id] = stateDelegate
    }
    
    func unregister(stateDelegate:OptimoveStateDelegate)
    {
        stateDalegates.removeValue(forKey: stateDelegate.id)
    }
    
    //MARK: - Private Methods
    private func updateSDKState()
    {
        var result = State.SDK.active
        
        for (_ ,state) in componentsState
        {
            switch state
            {
            case .unknown, .permitted,.denied:
                return
            case .inactive,.activeInternal:
                result = .inactive
            case .active:
                break
            }
        }
        sdkState = result
    }
    
    private func notifyDelegate(_ delegate: OptimoveStateDelegate)
    {
        switch sdkState
        {
        case .loading:
            delegate.didStartLoading()
        case .active:
            delegate.didBecomeActive()
        case .inactive:
            delegate.didBecomeInvalid(withErrors: initializationErrors ?? [])
        }
    }
}


