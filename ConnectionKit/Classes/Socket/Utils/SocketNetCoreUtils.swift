//
//  SocketNetCoreUtils.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/2/28.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation

public struct SocketNetCoreUtils {
    //https://stackoverflow.com/questions/4872196/how-to-get-the-wifi-gateway-address-on-the-iphone?noredirect=1&lq=1
    static func getDefaultGateway(addr: UnsafeMutablePointer<sockaddr_in>) -> Int {
        var mib = [
            CTL_NET,
            PF_ROUTE,
            0,
            AF_INET,
            NET_RT_FLAGS,
            RTF_GATEWAY
        ]
        var length: size_t = 0
        var result = -1
        
        guard sysctl(&mib, u_int(mib.count), nil, &length, nil, 0) >= 0 else {
            return result
        }
        
        guard length > 0 else {
            return result
        }
        
        let rawBuf: UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<CChar>.stride * length,
                                                                               alignment: MemoryLayout<CChar>.alignment)
        guard sysctl(&mib, u_int(mib.count), rawBuf, &length, nil, 0) >= 0 else {
            rawBuf.deallocate()
            return result
        }
        
        let rtax_max = Int(RTAX_MAX)
        let sa_tab = UnsafeMutableBufferPointer(
            start: UnsafeMutablePointer<UnsafeMutablePointer<sockaddr_in>>.allocate(capacity: rtax_max),
            count: rtax_max)
        
        defer {
            rawBuf.deallocate()
            sa_tab.baseAddress?.deallocate()
        }
        
        var index = 0
        var stride = 0
        var rtPtr: UnsafeMutablePointer<rt_msghdr>
        var saRawPtr: UnsafeMutableRawPointer
        var saPtr: UnsafeMutablePointer<sockaddr_in>
        var rt: rt_msghdr
        var ptr = rawBuf
        while index < length {
            ptr = ptr + stride
            rtPtr = ptr.assumingMemoryBound(to: rt_msghdr.self)
            rt = rtPtr[0]
            saRawPtr = ptr + MemoryLayout<rt_msghdr>.stride;
            saPtr = saRawPtr.assumingMemoryBound(to: sockaddr_in.self)

            for i in 0..<rtax_max {
                if rt.rtm_addrs & Int32(1 << i) > 0 {
                    sa_tab[i] = saPtr
                    saPtr = (saRawPtr + Int(saPtr[0].sin_len)).assumingMemoryBound(to: sockaddr_in.self)
                } else {

                }
            }

            if (rt.rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY)
                && (sa_tab[Int(RTAX_DST)][0].sin_family == AF_INET)
                && (sa_tab[Int(RTA_GATEWAY)][0].sin_family == AF_INET) {
                if sa_tab[Int(RTAX_DST)][0].sin_addr.s_addr == 0 {
                    let ifName = UnsafeMutablePointer<CChar>.allocate(capacity: 128)
                    if_indextoname(UInt32(rt.rtm_index), ifName)
                    if strcmp("en0", ifName) == 0 {
                        let found_addr = sa_tab[Int(RTAX_GATEWAY)]
                        memcpy(addr, found_addr, MemoryLayout<sockaddr_in>.stride)
                        result = 0
                    }
                    ifName.deallocate()
                }
            }
            
            stride = Int(rt.rtm_msglen)
            index = index + stride
        }
        
        return result;
    }
    
    //https://stackoverflow.com/questions/22807795/how-to-get-client-list-of-hotspot-in-ios-in-objective-c
    //https://opensource.apple.com/source/bootp/bootp-343.50.1/bootplib/arp.c.auto.html
    static func dumpLinkLayerInfo() -> [sockaddr_inarp]? {
        var mib = [
            CTL_NET,
            PF_ROUTE,
            0,
            AF_INET,
            NET_RT_FLAGS,
            RTF_LLINFO
        ]
        var length: size_t = 0
        
        guard sysctl(&mib, u_int(mib.count), nil, &length, nil, 0) >= 0 else {
            //route-sysctl-estimate
            return nil
        }
        
        guard length > 0 else {
            return nil
        }
        
        let rawBuf: UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<CChar>.stride * length,
                                                                               alignment: MemoryLayout<CChar>.alignment)
        defer {
            rawBuf.deallocate()
        }
        guard sysctl(&mib, u_int(mib.count), rawBuf, &length, nil, 0) >= 0 else {
            //"actual retrieval of routing table"
            return nil
        }
        
        var arp: [sockaddr_inarp] = []
        var index = 0
        var stride = 0
        var rtPtr: UnsafeMutablePointer<rt_msghdr>
        var sa: sockaddr_inarp
        var ptr = rawBuf
        /* ALIGN: trust that the kernel has taken care of alignment */
        while index < length {
            ptr = ptr + stride
            sa = ptr.load(fromByteOffset: MemoryLayout<rt_msghdr>.stride, as: sockaddr_inarp.self)
            arp.append(sa)
            
            rtPtr = ptr.assumingMemoryBound(to: rt_msghdr.self)
            stride = Int(rtPtr.pointee.rtm_msglen)
            index = index + stride
        }
        
        return arp
    }
    
    static public func getIpAddress() -> String? {
        var result: String? = nil
        // Get list of all interfaces on the local machine:
        var interfaces : UnsafeMutablePointer<ifaddrs>? = nil
        defer {
            freeifaddrs(interfaces)
        }
        if getifaddrs(&interfaces) == 0 {
            var temp_addr = interfaces
            while temp_addr != nil {
                if temp_addr?.pointee.ifa_addr.pointee.sa_family == sa_family_t(AF_INET) {
                    // Check if interface is en0 which is the wifi connection on the iPhone
                    if let ifa_name = temp_addr?.pointee.ifa_name {
                        let name = String.init(cString: ifa_name)
                        // Get NSString from C String
                        if name == "en0" || name == "bridge100" {
                            temp_addr?.pointee.ifa_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1, { (addr) -> Void in
                                result = String.init(cString: inet_ntoa(addr.pointee.sin_addr))
                            })
                        }
                    }

                }
                temp_addr = temp_addr?.pointee.ifa_next
            }
            
        }
        return result
    }

}




















