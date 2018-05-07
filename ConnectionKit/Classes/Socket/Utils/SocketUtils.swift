//
//  SocketUtils.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/8.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CoreFoundation
import SystemConfiguration.CaptiveNetwork

import AddressBook

public struct SocketUtils {
    static public func getGatewayInfo() -> sockaddr_in? {
        var gateway_sockaddr_in: sockaddr_in = sockaddr_in()
        let r = SocketNetCoreUtils.getDefaultGateway(addr: &gateway_sockaddr_in)
        if r >= 0 {
            return gateway_sockaddr_in
        } else {
            return nil
        }
    }
    
    static public func getGatewayInfoData(port: UInt16) -> Data? {
        var data: Data?
        if var gateway_sockaddr_in = self.getGatewayInfo() {
            gateway_sockaddr_in.sin_port = CFSwapInt16(port)
            data = Data.init(bytes: &gateway_sockaddr_in, count: Int(gateway_sockaddr_in.sin_len))
        }
        return data
    }
    
    static public func getGatewayIP() -> String? {
        var ipString: String?
        if let gateway_sockaddr_in = self.getGatewayInfo() {
            let gateway_in_addr = gateway_sockaddr_in.sin_addr
            ipString = String.init(cString: inet_ntoa(gateway_in_addr))
        }
        return ipString
    }
    
    static public func getGatewayInfoData() -> Data? {
        var data: Data?
        if var gateway_sockaddr_in = self.getGatewayInfo() {
            data = Data.init(bytes: &gateway_sockaddr_in, count: Int(gateway_sockaddr_in.sin_len))
        }
        return data
    }
    
    static public func getAddressData(address: Data, port: UInt16) -> Data {
        var sin = address.withUnsafeBytes {(ptr: UnsafePointer<sockaddr_in>) in
            return ptr.pointee
        }
        
        sin.sin_port = CFSwapInt16(port)
        return Data.init(bytes: &sin, count: Int(sin.sin_len))
    }
    
    static public func getARPTableInfo() -> Array<Data>? {
        guard let arps = SocketNetCoreUtils.dumpLinkLayerInfo() else {
            return nil
        }
        
        var info: [Data] = []
        for var llinfo in arps {
            let ipString = String(cString: inet_ntoa(llinfo.sin_addr))
            debugPrint(ipString)
            let data = Data.init(bytes: &llinfo, count: Int(llinfo.sin_len))
            info.append(data)
        }
        return info
    }
    

    static public func getWifiName() -> String? {
        var wifiName: String?
        guard let wifiInterfaces = CNCopySupportedInterfaces() else { return nil }
        for interfaceName in wifiInterfaces as Array {
            if let info = CNCopyCurrentNetworkInfo(interfaceName as! CFString) as Dictionary? {
                wifiName = info[kCNNetworkInfoKeySSID] as! String?
            }
        }
        
        return wifiName
    }

}




















