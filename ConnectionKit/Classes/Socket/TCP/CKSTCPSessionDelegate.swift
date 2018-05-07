//
//  CKSTCPSessionDelegate.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/4/1.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class CKSTCPSessionDelegate: NSObject {
    // MARK: URLSessionDelegate Overrides
    
    /// Overrides default behavior for GCDAsyncSocket method `socket(_:didConnectToHost:port:))`.
    open var sessionDidConnect: ((GCDAsyncSocket, String, UInt16) -> Void)?
    /// Overrides default behavior for GCDAsyncSocket method `socket(_:withError:))`.
    open var socketDidDisconnect: ((GCDAsyncSocket, Error?) -> Void)?
    /// Overrides default behavior for GCDAsyncSocket method `socket(_:idAcceptNewSocket:))`.
    open var sessionDidAcceptNewSocket: ((GCDAsyncSocket, GCDAsyncSocket) -> Void)?
    
    private var requests: [Int: CKSTCPRequest] = [:]
    private let lock = NSLock()
    
    weak var sessionManager: CKSTCPSessionManager?
    
    /// Access the task delegate for the specified task in a thread-safe manner.
    subscript(taskIdentifier: Int) -> CKSTCPRequest? {
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
        _ = requests.compactMap { $1.cancel() }
        requests.removeAll()
    }
    
    open override func responds(to selector: Selector) -> Bool {
        switch selector {
        case #selector(GCDAsyncSocketDelegate.socket(_:didConnectToHost:port:)):
            return sessionDidConnect != nil
        case #selector(GCDAsyncSocketDelegate.socketDidDisconnect(_:withError:)):
            return socketDidDisconnect != nil
        case #selector(GCDAsyncSocketDelegate.socket(_:didAcceptNewSocket:)):
            return sessionDidAcceptNewSocket != nil
        default:
            return type(of: self).instancesRespond(to: selector)
        }
    }
    
}

extension CKSTCPSessionDelegate: GCDAsyncSocketDelegate {
    
    //    /// Executed after it is determined that the request is not going to be retried
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
    private func completeTask(_ sock: GCDAsyncSocket, tag: Int, error: Error?) {
        //self[tag]?.delegate.urlSession(session, task: task, didCompleteWithError: error)
        self[tag] = nil
    }

    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        sessionDidConnect?(sock, host, port)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        socketDidDisconnect?(sock, err)
        if sock != self.sessionManager?.tcpSocket {
            let tag = sock.userData as! Int
            self[tag]?.cancel()
        } else {
            reset()
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        sessionDidAcceptNewSocket?(sock, newSocket)
        self.sessionManager?.insert(newSocket: newSocket)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        if let delegate = self[tag]?.delegate as? GCDAsyncSocketDelegate {
            delegate.socket!(sock, didWritePartialDataOfLength: partialLength, tag: tag)
        }
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        if let delegate = self[tag]?.delegate as? GCDAsyncSocketDelegate {
            delegate.socket!(sock, didWriteDataWithTag: tag)
            if self[tag] != nil {
                completeTask(sock, tag: tag, error: nil)
            }
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        if let delegate = self[tag]?.delegate as? GCDAsyncSocketDelegate {
            delegate.socket!(sock, didReadPartialDataOfLength: partialLength, tag: tag)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if let delegate = self[tag]?.delegate as? GCDAsyncSocketDelegate {
            delegate.socket!(sock, didRead: data, withTag: tag)
            if self[tag] != nil {
                completeTask(sock, tag: tag, error: nil)
            }
        }
    }
}
















