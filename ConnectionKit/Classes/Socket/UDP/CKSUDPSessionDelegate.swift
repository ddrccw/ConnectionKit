//
//  CKSUDPSessionDelegate.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/11.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class CKSUDPSessionDelegate: NSObject {
    // MARK: URLSessionDelegate Overrides
    
    /// Overrides default behavior for GCDAsyncUdpSocketDelegate method `udpSocket(_:didConnectToAddress:))`.
    open var sessionDidConnectToAddress: ((GCDAsyncUdpSocket, Data) -> Void)?
    /// Overrides default behavior for GCDAsyncUdpSocketDelegate method `udpSocket(_:didNotConnect:))`.
    open var sessionDidNotConnect: ((GCDAsyncUdpSocket, Error?) -> Void)?
    /// Overrides default behavior for GCDAsyncUdpSocketDelegate method `udpSocket(_:didClose:))`.
    open var sessionDidClose: ((GCDAsyncUdpSocket, Error?) -> Void)?

    /// Overrides default behavior for GCDAsyncUdpSocketDelegate method `udpSocket(_:didReceive:fromAddress:withFilterContext:)`.
    open var sessionDidReceiveData: ((GCDAsyncUdpSocket, Data, Data, Any?) -> Void)?

    private var requests: [Int: CKSUDPDataRequest] = [:]
    private let lock = NSLock()

    weak var sessionManager: CKSUDPSessionManager?
    
    /// Access the task delegate for the specified task in a thread-safe manner.
    subscript(taskIdentifier: Int) -> CKSUDPDataRequest? {
        get {
            lock.lock() ; defer { lock.unlock() }
            return requests[taskIdentifier]
        }
        set {
            lock.lock() ; defer { lock.unlock() }
            requests[taskIdentifier] = newValue
        }
    }

    public override init() {
        super.init()
    }

    func reset() {
        lock.lock() ; defer { lock.unlock() }
        requests.removeAll()
    }
    
    open override func responds(to selector: Selector) -> Bool {
        switch selector {
        case #selector(GCDAsyncUdpSocketDelegate.udpSocket(_:didConnectToAddress:)):
            return sessionDidConnectToAddress != nil
        case #selector(GCDAsyncUdpSocketDelegate.udpSocket(_:didNotConnect:)):
            return sessionDidNotConnect != nil
        case #selector(GCDAsyncUdpSocketDelegate.udpSocketDidClose(_:withError:)):
            return sessionDidClose != nil
        case #selector(GCDAsyncUdpSocketDelegate.udpSocket(_:didReceive:fromAddress:withFilterContext:)):
            return sessionDidReceiveData != nil
        default:
            return type(of: self).instancesRespond(to: selector)
        }
    }

}

extension CKSUDPSessionDelegate: GCDAsyncUdpSocketDelegate {
    
    /// Executed after it is determined that the request is not going to be retried
//    let completeTask: (URLSession, URLSessionTask, Error?) -> Void = { [weak self] session, task, error in
//        guard let strongSelf = self else { return }
//
//        strongSelf.taskDidComplete?(session, task, error)
//
//        strongSelf[task]?.delegate.urlSession(session, task: task, didCompleteWithError: error)
//
//        NotificationCenter.default.post(
//            name: Notification.Name.Task.DidComplete,
//            object: strongSelf,
//            userInfo: [Notification.Key.Task: task]
//        )
//
//        strongSelf[task] = nil
//    }
    private func completeTask(_ sock: GCDAsyncUdpSocket, tag: Int, error: Error?) {
        //self[tag]?.delegate.urlSession(session, task: task, didCompleteWithError: error)
        self[tag] = nil
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        sessionDidConnectToAddress?(sock, address)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        sessionDidNotConnect?(sock, error)
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        sessionDidClose?(sock, error)
        reset()
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        if let delegate = self[tag]?.delegate as? GCDAsyncUdpSocketDelegate {
            delegate.udpSocket!(sock, didSendDataWithTag: tag)
            if self[tag] != nil {
                completeTask(sock, tag: tag, error: nil)
            }
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        if let delegate = self[tag]?.delegate as? GCDAsyncUdpSocketDelegate {
            delegate.udpSocket!(sock, didNotSendDataWithTag: tag, dueToError: error)
            if self[tag] != nil {
                completeTask(sock, tag: tag, error: nil)
            }
        }
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        sessionDidReceiveData?(sock, data, address, filterContext)
    }
}




















