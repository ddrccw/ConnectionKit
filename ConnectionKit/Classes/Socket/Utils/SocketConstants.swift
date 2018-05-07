//
//  SocketDefine.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/2/28.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation

public struct SocketConstants {
    static let Timeout = 60.0
    static let MessageFinish = "finish"
    static let ErrorMessageTOKEN = "ErrorMessage"
    
    public struct UDP {
        //UDP通信服务 默认端口
        public static let ServerPort: UInt16 = 8099
    }

    public struct TCP {
        static let ByteSizeHeader: UInt64 = 1024 * 10
        static let ByteSizeScreenshot: UInt64 = 1024 * 40
        static let ByteSizeData: UInt64 = 1024 * 4
        
        //TCP文件传输监听 默认端口
        public static let ServerPort: UInt16 = 8080
    }
    
//    /**
//     * UDP通信服务 默认端口
//     */
//    static int16_t YKFCKUDPServerPort = 8099;
//    //static int16_t YKFCKUDPClientPort = 8100;
//
//    /**
//     * TCP文件传输监听 默认端口
//     */
//    static int16_t YKFCKTCPServerPort = 8080;

}


