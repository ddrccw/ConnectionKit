//
//  CKSUDPRequest.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/11.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

// MARK: -
class CKSUDPDataRequest : CKSRequest
    <CKSUDPSessionManager, GCDAsyncUdpSocket,
    CKSAnyTaskConvertible<GCDAsyncUdpSocket, CKSTask>,
    CKSUDPDataTaskDelegate, CKSUDPDataTaskDelegate, CKSUDPDataTaskDelegate>
{
    struct Requestable: CKSTaskConvertible {
        let task: CKSTask
        func task(sock: GCDAsyncUdpSocket, adapter: CKSTaskAdapter?) throws -> CKSTask {
            do {
                return try task.adapt(using: adapter)
            } catch {
                throw CKSUDPAdaptError(error: error)
            }
        }
    }
    
    /// Resumes the request.
    override func resume() {
        super.resume()
        do {
            let task = self.task!
            if let data = try task.payload?.asData() {
                if let address = task.targetAddress {
                    sock.send(data,
                              toAddress: address,
                              withTimeout: SocketConstants.Timeout,
                              tag: task.taskIdentifier)
                } else {
                    sock.send(data,
                              withTimeout: SocketConstants.Timeout,
                              tag: task.taskIdentifier)
                }
            }
        } catch {
            delegate.error = error
        }
        
        //        NotificationCenter.default.post(
        //            name: Notification.Name.Task.DidResume,
        //            object: self,
        //            userInfo: [Notification.Key.Task: task]
        //        )
    }
    

}



























