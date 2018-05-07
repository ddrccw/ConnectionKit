//
//  CKSTCPSessionManager.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/4/1.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class CKSTCPSessionManager: CKSSessionManagerProtocol  {
    typealias Request = CKSTCPDataRequest
    
    let queue = DispatchQueue(label: "connetionkit.tcp.session-manager." + UUID().uuidString)

    private var lastConnectingAddress: Data?
    internal let tcpSocket: GCDAsyncSocket

    let delegate: CKSTCPSessionDelegate
    let lock = NSLock()
    var connectedSockets = Set<GCDAsyncSocket>()
    func insert(newSocket: GCDAsyncSocket) {
        lock.lock(); defer { lock.unlock() }
        connectedSockets.insert(newSocket)
    }
    
    /// The request adapter called each time a new request is created.
    var adapter: CKSTaskAdapter?
    
    // MARK: Private - Request Implementation
    
    private func request(_ requestable: CKSTCPDataRequest.Requestable?, failedWith error: Error) -> CKSTCPDataRequest {
        var requestTask: CKSTCPDataRequest.RequestTask = .data(nil, nil)
        
        if let requestable = requestable {
            switch requestable {
            case let .write(task):
                let originalTask = CKSAnyTaskConvertible<GCDAsyncSocket, CKSTask>(requestable)
                requestTask = .data(originalTask, task)
            case let .read(_, task):
                let originalTask = CKSAnyTaskConvertible<GCDAsyncSocket, CKSTask>(requestable)
                requestTask = .data(originalTask, task)
            }
            
        }
        //        let underlyingError = error.underlyingAdaptError ?? error
        let request = CKSTCPDataRequest(sessionManager: self, sock: tcpSocket, requestTask: requestTask)
        //        if let retrier = retrier, error is AdaptError {
        //            allowRetrier(retrier, toRetry: request, with: underlyingError)
        //        } else {
        //            if startRequestsImmediately { request.resume() }
        //        }
        return request
    }
    
    private func upload(_ uploadable: CKSTCPUploadRequest.Uploadable?, failedWith error: Error) -> CKSTCPUploadRequest {
        var uploadTask: CKSTCPUploadRequest.RequestTask = .upload(nil, nil)

        if let uploadable = uploadable {
            switch uploadable {
            case let .file(_, task):
                let originalTask = CKSAnyTaskConvertible<GCDAsyncSocket, CKSTask>(uploadable)
                uploadTask = .upload(originalTask, task)
            }
        }

//        let underlyingError = error.underlyingAdaptError ?? error
        let upload = CKSTCPUploadRequest(sessionManager: self, sock: tcpSocket, requestTask: uploadTask)

//        if let retrier = retrier, error is AdaptError {
//            allowRetrier(retrier, toRetry: upload, with: underlyingError)
//        } else {
//            if startRequestsImmediately { upload.resume() }
//        }

        return upload
    }

    private func download(_ downloadable: CKSTCPDownloadRequest.Downloadable?, failedWith error: Error) -> CKSTCPDownloadRequest {
        var downloadTask: CKSTCPUploadRequest.RequestTask = .download(nil, nil)
        
        if let downloadable = downloadable {
            switch downloadable {
            case let .file(_, _, task):
                let originalTask = CKSAnyTaskConvertible<GCDAsyncSocket, CKSTask>(downloadable)
                downloadTask = .download(originalTask, task)
            }
        }
        
        //        let underlyingError = error.underlyingAdaptError ?? error
        let download = CKSTCPDownloadRequest(sessionManager: self, sock: tcpSocket, requestTask: downloadTask)
        
        //        if let retrier = retrier, error is AdaptError {
        //            allowRetrier(retrier, toRetry: upload, with: underlyingError)
        //        } else {
        //            if startRequestsImmediately { upload.resume() }
        //        }
        
        return download
    }

    
    public init(
        delegate: CKSTCPSessionDelegate = CKSTCPSessionDelegate()
        )
    {
        tcpSocket = GCDAsyncSocket(delegate: delegate, delegateQueue: queue)
        self.delegate = delegate
        self.delegate.sessionManager = self
    }

    func request(payload: CKSTask.Payload?, to address: Data? = nil) -> CKSTCPDataRequest {
        var task = CKSTask(payload: payload, fromAddress: address ?? lastConnectingAddress)
        let requestable = CKSTCPDataRequest.Requestable.write(task)
        let orignalTask = CKSAnyTaskConvertible<GCDAsyncSocket, CKSTask>(requestable)
        do {
            try task = orignalTask.task(sock: tcpSocket, adapter: adapter)
            let request = CKSTCPDataRequest(sessionManager: self, sock: tcpSocket, requestTask: .data(orignalTask, task))

            delegate[task.taskIdentifier] = request

            request.resume()
            return request
        } catch {
            return request(requestable, failedWith: error)
        }
    }

    func request(expectedContentLength: Int64, from sock: GCDAsyncSocket) -> CKSTCPDataRequest {
        var task = CKSTask(payload: .data(Data()))
        task.expectedContentLength = expectedContentLength
        sock.userData = task.taskIdentifier
        let requestable = CKSTCPDataRequest.Requestable.read(sock, task)
        let orignalTask = CKSAnyTaskConvertible<GCDAsyncSocket, CKSTask>(requestable)
        do {
            try task = orignalTask.task(sock: tcpSocket, adapter: adapter)
            let request = CKSTCPDataRequest(sessionManager: self, sock: tcpSocket, requestTask: .data(orignalTask, task))
            
            delegate[task.taskIdentifier] = request
            
            request.resume()
            return request
        } catch {
            return request(requestable, failedWith: error)
        }
    }


    func upload(_ file: File, countOfBytesPerRead: Int64) -> CKSTCPUploadRequest {
        let task = CKSUploadTask(payload: .file(file), countOfBytesPerRead: countOfBytesPerRead)
        let uploadable = CKSTCPUploadRequest.Uploadable.file(file, task)
        let orignalTask = CKSAnyTaskConvertible<GCDAsyncSocket, CKSTask>(uploadable)
        do {
            let finalTask = try orignalTask.task(sock: tcpSocket, adapter: adapter)
            let request = CKSTCPUploadRequest(sessionManager: self, sock: tcpSocket, requestTask: .upload(orignalTask, finalTask))

            delegate[task.taskIdentifier] = request

            request.resume()
            return request
        } catch {
            return upload(uploadable, failedWith: error)
        }
    }

    func download(to file: File, from sock: GCDAsyncSocket, countOfBytesPerWrite: Int64) -> CKSTCPDownloadRequest
    {
        let task = CKSDownloadTask(payload: .file(file), countOfBytesPerWrite: countOfBytesPerWrite)
        let downloadable = CKSTCPDownloadRequest.Downloadable.file(file, sock, task)
        let orignalTask = CKSAnyTaskConvertible<GCDAsyncSocket, CKSTask>(downloadable)
        do {
            let finalTask = try orignalTask.task(sock: tcpSocket, adapter: adapter)
            let request = CKSTCPDownloadRequest(sessionManager: self, sock: tcpSocket, requestTask: .download(orignalTask, finalTask))

            delegate[task.taskIdentifier] = request

            request.resume()
            return request
        } catch {
            return download(downloadable, failedWith: error)
        }
    }

    deinit {
        disconnectAll()
    }
    
    func disconnectAll() {
        tcpSocket.disconnect()
        lock.lock()
        _ = connectedSockets.map { $0.disconnect() }
        connectedSockets.removeAll()
        lock.unlock()
    }
    
    func disConnect(from sock: GCDAsyncSocket) {
        sock.disconnect()
        lock.lock()
        _ = connectedSockets.index(of: sock).map { connectedSockets.remove(at: $0) }
        lock.unlock()
    }
    
    func connect(to address: Data) throws {
        try tcpSocket.connect(toAddress: address)
    }
    
    func accept(onPort: UInt16) throws {
        try tcpSocket.accept(onPort: onPort)
    }
    
    func isConnected() -> Bool {
        return tcpSocket.isConnected
    }

}

















