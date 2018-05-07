//
//  CKSTCPRequest.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/4/7.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

/// Responsible for sending a request and receiving the response and associated data from the server, as well as
/// managing its underlying `URLSessionTask`.
class CKSTCPRequest: CKSRequest
    <CKSTCPSessionManager, GCDAsyncSocket,
    CKSAnyTaskConvertible<GCDAsyncSocket, CKSTask>,
    CKSTCPDataTaskDelegate, CKSTCPDataTaskDelegate, CKSTCPDataTaskDelegate> {
}


// MARK: -

/// Specific type of `Request` that manages an underlying `URLSessionDownloadTask`.
class CKSTCPDataRequest: CKSTCPRequest {

    enum Requestable: CKSTaskConvertible {
        case write(CKSTask?)
        case read(GCDAsyncSocket?, CKSTask?)
        
        func task(sock: GCDAsyncSocket, adapter: CKSTaskAdapter?) throws -> CKSTask {
            do {
                switch self {
                case let .write(task),
                     let .read(_, task):
                    return try task!.adapt(using: adapter)
                }
                    
            } catch {
                throw CKSTCPAdaptError(error: error)
            }
        }
    }
    
    /// Resumes the request.
    override func resume() {
        super.resume()
        do {
            let requestable: Requestable = (self.originalTask?.base())!
            switch requestable {
            case .write(_):
                if let task = self.task, let data = try task.payload?.asData() {
                    task.expectedContentLength = Int64(data.count)
                    self.writeProgress.totalUnitCount = task.expectedContentLength
                    sock.write(data,
                               withTimeout: SocketConstants.Timeout,
                               tag: task.taskIdentifier)
                }
            case let .read(sock, _):
                if let task = self.task, let sock = sock {
                    self.readProgress.totalUnitCount = task.expectedContentLength
                    sock.readData(toLength: UInt(task.expectedContentLength),
                                  withTimeout: SocketConstants.Timeout,
                                  buffer: nil,
                                  bufferOffset: 0,
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
    
    var dataTaskdelegate: CKSDataTaskDelegate { return delegate as! CKSDataTaskDelegate}
    /// The progress of uploading the payload to the server for the upload request.
    open var writeProgress: Progress { return dataTaskdelegate.progress }
    open var readProgress: Progress { return dataTaskdelegate.progress }

    // MARK: Upload Progress
    
    /// Sets a closure to be called periodically during the lifecycle of the `UploadRequest` as data is sent to
    /// the server.
    ///
    /// After the data is sent to the server, the `progress(queue:closure:)` APIs can be used to monitor the progress
    /// of data being read from the server.
    ///
    /// - parameter queue:   The dispatch queue to execute the closure on.
    /// - parameter closure: The code to be executed periodically as data is sent to the server.
    ///
    /// - returns: The request.
    @discardableResult
    open func progress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
        dataTaskdelegate.progressHandler = (closure, queue)
        return self
    }

}

class CKSTCPUploadRequest: CKSTCPDataRequest {
    var uploadInputStream: InputStream?

    enum Uploadable: CKSTaskConvertible {
        //case data(Data, CKSTask?)
        case file(File, CKSTask?)
        //case stream(InputStream, CKSTask?)
        
        func task(sock: GCDAsyncSocket, adapter: CKSTaskAdapter?) throws -> CKSTask {
            do {
                switch self {
                case let .file(_, task):
                    return try task!.adapt(using: adapter)
                }
            } catch {
                throw CKSTCPAdaptError(error: error)
            }
        }
    }
    
    override var task: CKSUploadTask? { return delegate.task as? CKSUploadTask }

    override func resume() {
        guard let _ = task else { delegate.queue.isSuspended = false ; return }
        DispatchQueue.global(qos: .utility).async {
            //TODO: check task valid, like url
            do {
                //CKSUploadTask
                guard let task = self.task, let fileURL = try task.payload?.asFileURL() else {
                    return
                }
                self.uploadInputStream = InputStream(url: fileURL)
                guard let uploadInputStream = self.uploadInputStream else {
                    return
                }

                uploadInputStream.open()
                defer { uploadInputStream.close() }
                while uploadInputStream.hasBytesAvailable {
                    let streamBufferSize = Int(task.countOfBytesPerRead)
                    var buffer = [UInt8](repeating: 0, count: streamBufferSize)
                    let bytesRead = uploadInputStream.read(&buffer, maxLength: streamBufferSize)
                    if let error = uploadInputStream.streamError {
                        throw CKSTCPError.multipartEncodingFailed(reason: .inputStreamReadFailed(error: error))
                    }

                    if bytesRead > 0 {
                        if buffer.count != bytesRead {
                            buffer = Array(buffer[0..<bytesRead])
                        }
                        
                        let completedUnitCount = self.writeProgress.completedUnitCount;
                        self.sessionManager?.request(payload: .data(Data(buffer)))
                            .progress(queue: DispatchQueue.global(qos: .utility), closure: { [weak self] (progress) in
                                //self?.writeProgress.completedUnitCount = completedUnitCount + progress.completedUnitCount
                            }).response(completionHandler: { [weak self](response) in
                                guard let strongSelf = self else {
                                    uploadInputStream.close()
                                    self?.delegate.queue.isSuspended = false
                                    return
                                }
                                
                                if let error = response.error {
                                    uploadInputStream.close()
                                    strongSelf.delegate.error = CKSTCPError.dataUploadFailed(error: error)
                                    strongSelf.delegate.queue.isSuspended = false
                                } else {
                                    strongSelf.writeProgress.completedUnitCount = strongSelf.writeProgress.completedUnitCount + Int64(bytesRead)
                                    if strongSelf.writeProgress.completedUnitCount >= task.expectedContentLength {
                                        uploadInputStream.close()
                                        strongSelf.delegate.queue.isSuspended = false
                                    }
                                    
                                    debugPrint("\(strongSelf.writeProgress.completedUnitCount)")
                                }
                            }
                        )
                    } else {
                        break
                    }
                }
            } catch let error as CKSTCPError {
                self.delegate.error = error
                self.delegate.queue.isSuspended = false
            } catch {
                self.delegate.error = CKSTCPError.dataUploadFailed(error: error)
                self.delegate.queue.isSuspended = false
            }
        }
    }
    
    override func cancel() {
        uploadInputStream?.close()
        delegate.queue.isSuspended = false
    }
}

class CKSTCPDownloadRequest: CKSTCPDataRequest {
    var downloadOutputStream: OutputStream?
    enum Downloadable: CKSTaskConvertible {
        //case data(Data, CKSTask?)
        case file(File, GCDAsyncSocket?, CKSTask?)
        //case stream(InputStream, CKSTask?)
        
        func task(sock: GCDAsyncSocket, adapter: CKSTaskAdapter?) throws -> CKSTask {
            do {
                switch self {
                case let .file(_, _, task):
                    return try task!.adapt(using: adapter)
                }
            } catch {
                throw CKSTCPAdaptError(error: error)
            }
        }
    }

    override var task: CKSDownloadTask? { return delegate.task as? CKSDownloadTask }

    private func readPartialData(expectedContentLength: Int64, from socket: GCDAsyncSocket) {
        guard let downloadOutputStream = self.downloadOutputStream else {
            return
        }
        let lastCompletedUnitCount = self.readProgress.completedUnitCount
        self.sessionManager?.request(expectedContentLength: expectedContentLength, from: socket)
            .progress(queue: DispatchQueue.global(qos: .utility), closure: { [weak self] (progress) in
                self?.readProgress.completedUnitCount = lastCompletedUnitCount + progress.completedUnitCount;
            }).response(completionHandler: { [weak self](response) in
                guard let strongSelf = self else {
                    downloadOutputStream.close()
                    self?.delegate.queue.isSuspended = false
                    return
                }
                
                if let error = response.error {
                    downloadOutputStream.close()
                    strongSelf.delegate.error = CKSTCPError.dataDownloadFailed(error: error)
                    strongSelf.delegate.queue.isSuspended = false
                } else {
                    if let data = response.data {
                        let count = data.count
                        strongSelf.readProgress.completedUnitCount = lastCompletedUnitCount + Int64(count)
                        data.withUnsafeBytes({ (ptr) -> Void in
                            downloadOutputStream.write(ptr, maxLength: count)
                        })
                        
                        if let error = downloadOutputStream.streamError {
                            downloadOutputStream.close()
                            strongSelf.delegate.error = CKSTCPError.multipartEncodingFailed(reason: .outputStreamWriteFailed(error: error))
                            strongSelf.delegate.queue.isSuspended = false
                            return
                        }
                    }
                    
                    debugPrint(
                        "totalUnitCount=\(strongSelf.readProgress.totalUnitCount), completedUnitCount=\(strongSelf.readProgress.completedUnitCount)")
                    if strongSelf.readProgress.totalUnitCount > strongSelf.readProgress.completedUnitCount {
                        let left = strongSelf.readProgress.totalUnitCount - strongSelf.readProgress.completedUnitCount
                        var readToLength = expectedContentLength;
                        if left < (strongSelf.task?.countOfBytesPerWrite)! {
                            readToLength = left
                        }
                        strongSelf.readPartialData(expectedContentLength: readToLength, from: socket)
                    } else {
                        downloadOutputStream.close()
                        strongSelf.delegate.queue.isSuspended = false
                    }
                }
            })
    }
    
    override func resume() {
        guard let _ = task else { delegate.queue.isSuspended = false ; return }

        DispatchQueue.global(qos: .utility).async {
            //TODO: check task valid, like url
            do {
                //CKSDownloadTask
                guard let task = self.task,
                    let fileURL = try task.payload?.asFileURL(), 
                    let downloadable: Downloadable = self.originalTask?.base()
                    else {
                    return
                }
                
                if case let .file(_, sock, _) = downloadable {
                    self.downloadOutputStream = OutputStream(url: fileURL, append: false)
                    guard let downloadOutputStream = self.downloadOutputStream else {
                        return
                    }

                    downloadOutputStream.open()
                    self.readPartialData(expectedContentLength: task.countOfBytesPerWrite, from: sock!)
                } else {
                    return
                }
            } catch {
                self.delegate.error = CKSTCPError.dataUploadFailed(error: error)
                self.delegate.queue.isSuspended = false
            }
        }
    }
    
    override func cancel() {
        downloadOutputStream?.close()
        delegate.queue.isSuspended = false
    }
}





















