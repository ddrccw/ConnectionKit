//
//  HotspotManager.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/8.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import Reachability

public class HotspotManager {
    public static let `default` = HotspotManager()
    private let reachability = Reachability()
    private var gatewayAddr: Data?
    private var arpTable: [Data]?
    
    private init() {
        scanNetworkInterfaces()
    }
    
    public func isReachable() -> Bool {
        return reachability?.connection != .none
    }
    
    func scanNetworkInterfaces() {
        gatewayAddr = SocketUtils.getGatewayInfoData()
        arpTable = SocketUtils.getARPTableInfo()
    }
    
    public func isHotspot() -> Bool {
        if isReachable() && gatewayAddr == nil {
            return true
        }
        return false
    }
    
    func hotspotAddress() -> Data? {
        if isHotspot() {
            return gatewayAddr
        }
        return nil;
    }
}
