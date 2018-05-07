//
//  CKSUDPSessionManager.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/10.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class CKSUDPSessionManager: CKSSessionManagerProtocol  {
    typealias Request = CKSUDPDataRequest

    let queue = DispatchQueue(label: "connetionkit.udp.session-manager." + UUID().uuidString)
    
    private var lastConnectingAddress: Data?
    private let udpSocket: GCDAsyncUdpSocket
    let delegate: CKSUDPSessionDelegate
    
    /// The request adapter called each time a new request is created.
    var adapter: CKSTaskAdapter?

    // MARK: Private - Request Implementation
    
    private func request(_ task: CKSTask?, failedWith error: Error) -> CKSUDPDataRequest {
        var requestTask: CKSUDPDataRequest.RequestTask = .data(nil, nil)

        if let task = task {
            let originalTask: CKSAnyTaskConvertible<GCDAsyncUdpSocket, CKSTask> = CKSAnyTaskConvertible(CKSUDPDataRequest.Requestable(task: task))
            requestTask = .data(originalTask, task)
        }

//        let underlyingError = error.underlyingAdaptError ?? error
        let request = CKSUDPDataRequest(sessionManager: self, sock: udpSocket, requestTask: requestTask)

//        if let retrier = retrier, error is AdaptError {
//            allowRetrier(retrier, toRetry: request, with: underlyingError)
//        } else {
//            if startRequestsImmediately { request.resume() }
//        }

        return request
    }

    public init(
        delegate: CKSUDPSessionDelegate = CKSUDPSessionDelegate()
        )
    {
        udpSocket = GCDAsyncUdpSocket(delegate: delegate, delegateQueue: queue)
        self.delegate = delegate
        self.delegate.sessionManager = self
    }
    
    deinit {
        close()
    }
    
    func request(payload: CKSTask.Payload?, to address: Data? = nil) -> CKSUDPDataRequest {
        var task = CKSTask(payload: payload, toAddress: address ?? lastConnectingAddress)
        let orignalTask = CKSAnyTaskConvertible<GCDAsyncUdpSocket, CKSTask>(CKSUDPDataRequest.Requestable(task: task))
        do {
            try task = orignalTask.task(sock: udpSocket, adapter: adapter)
            let request = CKSUDPDataRequest(sessionManager: self, sock: udpSocket, requestTask: .data(orignalTask, task))

            delegate[task.taskIdentifier] = request

            request.resume()
            return request
        } catch {
            return request(task, failedWith: error)
        }
    }
    
    func isConnected() -> Bool {
        return udpSocket.isConnected()
    }
    
    func connect(to address: Data) throws {
        try udpSocket.connect(toAddress: address)
        lastConnectingAddress = address
    }
    
    func bind(port:UInt16) throws {
        try udpSocket.bind(toPort: port)
    }
    
    func beginReceiving() throws {
        try udpSocket.beginReceiving()
    }
    
    func close() {
        udpSocket.close()
    }
}









