//
//  CKSRequest.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/4/7.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

protocol CKSRequestProtocol {
    /// A closure executed when monitoring upload or download progress of a request.
    typealias ProgressHandler = (Progress) -> Void
    associatedtype Socket
    associatedtype TaskConvertible
    associatedtype RequestTask
    associatedtype SessionManager
    
    var sock: Socket { get }

    init(sessionManager: SessionManager?, sock: Socket,  requestTask: RequestTask, error: Error?)
    func resume()
    func cancel()
}

class CKSRequest
    <SessionManager: CKSSessionManagerProtocol, Socket,
    TaskConvertible: CKSTaskConvertible,
    DataTaskDelegate: CKSDataTaskDelegate, UploadTaskDelegate: CKSDataTaskDelegate, DownloadTaskDelegate: CKSDataTaskDelegate
>: CKSRequestProtocol {
    enum RequestTask {  //originalTask，task
        case data(TaskConvertible?, CKSTask?)
        case upload(TaskConvertible?, CKSTask?)
        case download(TaskConvertible?, CKSTask?)
    }
    
    // MARK: Properties
    /// The underlying task.
    open var task: CKSTask? { return delegate.task }
    
    /// The session belonging to the underlying task.
    var sock: Socket
    let originalTask: TaskConvertible?
    
    private var taskDelegate: CKSTaskDelegate
    private var taskDelegateLock = NSLock()
    
    // The delegate for the underlying task.
    open internal(set) var delegate: CKSTaskDelegate {
        get {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            return taskDelegate
        }
        set {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            taskDelegate = newValue
        }
    }
    
    private weak var _sessionManager: SessionManager?
    private var sessionManagerLock = NSLock()
    
    open internal(set) var sessionManager: SessionManager? {
        get {
            sessionManagerLock.lock() ; defer { sessionManagerLock.unlock() }
            return _sessionManager
        }
        set {
            sessionManagerLock.lock() ; defer { sessionManagerLock.unlock() }
            _sessionManager = newValue
        }
    }

    required init(sessionManager: SessionManager?, sock: Socket, requestTask: RequestTask, error: Error? = nil) {
        _sessionManager = sessionManager
        self.sock = sock
        switch requestTask {
        case .data(let originalTask, let task):
            taskDelegate = DataTaskDelegate(task: task)
            self.originalTask = originalTask
        case .upload(let originalTask, let task):
            taskDelegate = UploadTaskDelegate(task: task) 
            self.originalTask = originalTask
        case .download(let originalTask, let task):
            taskDelegate = DownloadTaskDelegate(task: task)
            self.originalTask = originalTask
        }
        
        delegate.error = error
        //delegate.queue.addOperation { self.endTime = CFAbsoluteTimeGetCurrent() }
    }
    
    
    func resume() {
        guard let _ = task else { delegate.queue.isSuspended = false ; return }
    }
    
    func cancel() {
        delegate.queue.isSuspended = false
    }
}


class CKSDataRequest
    <SessionManager: CKSSessionManagerProtocol, Socket,
    TaskConvertible: CKSTaskConvertible,
    DataTaskDelegate: CKSDataTaskDelegate, UploadTaskDelegate: CKSDataTaskDelegate, DownloadTaskDelegate: CKSDataTaskDelegate
>: CKSRequest<SessionManager, Socket, TaskConvertible, DataTaskDelegate, UploadTaskDelegate, DownloadTaskDelegate> {
}

































