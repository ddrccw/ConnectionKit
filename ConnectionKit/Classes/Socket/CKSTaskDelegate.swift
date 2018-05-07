//
//  CKSUDPTaskDelegate.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/11.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class CKSTaskDelegate: NSObject {
    // MARK: Properties

    /// The serial operation queue used to execute all operations after the task completes.
    open let queue: OperationQueue

    /// The data returned by the server.
    public var data: Data? { return nil }

    /// The error generated throughout the lifecyle of the task.
    public var error: Error?
    
    var task: CKSTask? {
        set {
            taskLock.lock(); defer { taskLock.unlock() }
            _task = newValue
        }
        get {
            taskLock.lock(); defer { taskLock.unlock() }
            return _task
        }
    }

    private var _task: CKSTask? {
        didSet { reset() }
    }
    
    private let taskLock = NSLock()

    required init(task: CKSTask?) {
        _task = task
        self.queue = {
            let operationQueue = OperationQueue()
            
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.isSuspended = true
            operationQueue.qualityOfService = .utility
            return operationQueue
        }()
    }
    
    func reset() {
        error = nil
        //initialResponseTime = nil
    }
}

class CKSDataTaskDelegate : CKSTaskDelegate {
    override var data: Data? {
        //        if dataStream != nil {
        //            return nil
        //        } else {
        //            return mutableData
        //        }
        
        return mutableData
    }
    
    fileprivate var mutableData: Data
    //var uploadTask: CKSUploadTask? { return task as? CKSUploadTask }
    
    var progress: Progress
    var progressHandler: (closure: CKSRequestProtocol.ProgressHandler, queue: DispatchQueue)?

    required init(task: CKSTask?) {
        mutableData = Data()
        progress = Progress(totalUnitCount: (task?.expectedContentLength) ?? 0)
        super.init(task: task)
        progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: nil)
    }

    override func reset() {
        super.reset()
        progress.removeObserver(self, forKeyPath: "fractionCompleted")
        progress = Progress(totalUnitCount: (task?.expectedContentLength) ?? 0)
        progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: nil)
    }
    
    deinit {
        progress.removeObserver(self, forKeyPath: "fractionCompleted")
    }
    ////////////////////////////////////////////////////////////////////////////////
    // MARK: - Progress Tracking
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "fractionCompleted" {
            if let progressHandler = progressHandler {
                progressHandler.queue.async { progressHandler.closure(self.progress) }
            }
        }
    }
}

class CKSTCPDataTaskDelegate: CKSDataTaskDelegate, GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        progress.completedUnitCount = Int64(partialLength)
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        queue.isSuspended = false
    }
    
    func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        progress.completedUnitCount = Int64(partialLength)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        mutableData = data
        queue.isSuspended = false
    }
}


class CKSUDPDataTaskDelegate : CKSDataTaskDelegate, GCDAsyncUdpSocketDelegate {
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        queue.isSuspended = false
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        self.error = error
        queue.isSuspended = false
    }
}

















