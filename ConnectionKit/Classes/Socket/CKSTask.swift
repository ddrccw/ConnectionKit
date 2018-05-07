//
//  CKSUDPTask.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/17.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation

/// A type that can inspect and optionally adapt a `URLRequest` in some manner if necessary.
protocol CKSTaskAdapter {
    /// Inspects and adapts the specified `URLRequest` in some manner if necessary and returns the result.
    ///
    /// - parameter urlRequest: The URL request to adapt.
    ///
    /// - throws: An `Error` if the adaptation encounters an error.
    ///
    /// - returns: The adapted `URLRequest`.
    func adapt(_ task: CKSTask) throws -> CKSTask
}

protocol CKSTaskConvertible {
    associatedtype Socket
    associatedtype Task
    func task(sock: Socket, adapter: CKSTaskAdapter?) throws -> Task
}

final class CKSAnyTaskConvertible<Socket, Task>: CKSTaskConvertible {
    private class _AnyTaskConvertibleBase<Socket, Task>: CKSTaskConvertible {
        func task(sock: Socket, adapter: CKSTaskAdapter?) throws -> Task {
            fatalError("Must override")
        }
    }
    
    private final class _AnyTaskConvertibleBox<Base: CKSTaskConvertible>: _AnyTaskConvertibleBase<Base.Socket, Base.Task> {
        var base: Base
        
        init(_ base: Base) {
            self.base = base
        }
        
        var _base: Any {
            return base
        }

        override func task(sock: Base.Socket, adapter: CKSTaskAdapter?) throws -> Base.Task {
            return try base.task(sock: sock, adapter: adapter)
        }
    }
    
    private var _box: _AnyTaskConvertibleBase<Socket, Task>
    init<Base: CKSTaskConvertible>(_ base: Base) where Base.Socket == Socket, Base.Task == Task {
        _box = _AnyTaskConvertibleBox<Base>(base)
    }
    
    func task(sock: Socket, adapter: CKSTaskAdapter?) throws -> Task {
        return try _box.task(sock: sock, adapter: adapter)
    }
    
    func base<Base: CKSTaskConvertible>() -> Base? {
        let box = _box as? _AnyTaskConvertibleBox<Base>
        return box?.base
    }
}

public protocol PayloadConvertible {
    func asData() throws -> Data
    func asFileURL() throws -> URL
}

extension Data: PayloadConvertible {
    public func asData() throws -> Data {
        return self
    }
    public func asFileURL() throws -> URL {
        guard let path = String(data: self, encoding: .utf8) else {
            throw CKSUDPError.invalidPayload(payload: self)
        }
        return URL(fileURLWithPath: path)
    }
}

extension String: PayloadConvertible {
    public func asData() throws -> Data {
        guard let data = self.data(using: .utf8) else {
            throw CKSUDPError.invalidPayload(payload: self)
        }
        return data
    }
    public func asFileURL() throws -> URL {
        return URL(fileURLWithPath: self)
    }
}

extension File: PayloadConvertible {
    public func asData() throws -> Data {
        guard let data = self.toJSONString()?.data(using: .utf8) else {
            throw CKSUDPError.invalidPayload(payload: self)
        }
        return data
    }
    
    public func asFileURL() throws -> URL {
        guard let path = filePath else {
            throw CKSUDPError.invalidPayload(payload: self)
        }
        return URL(fileURLWithPath: path)
    }
}

var g_taskUniqueID: Int32 = 0

public class CKSTask {
    
    /* an identifier for this task, assigned by and unique to the owning session */
    lazy var taskIdentifier: Int = {
        return Int(OSAtomicIncrement32Barrier(&g_taskUniqueID))
    }()

    
    var payload: Payload?
    var sourceAddress: Data?
    var targetAddress: Data?
    var expectedContentLength: Int64 = 0 //number of body bytes we expect to send or write

    enum Payload: PayloadConvertible {
        case data(Data)
        case text(String)
        case file(File)
        
        func asData() throws -> Data {
            switch self {
            case .data(let data):
                return try data.asData()
            case .text(let text):
                return try text.asData()
            case .file(let file):
                return try file.asData()
            }
        }
        
        func asFileURL() throws -> URL {
            switch self {
            case .data(let data):
                return try data.asFileURL()
            case .text(let text):
                return try text.asFileURL()
            case .file(let file):
                return try file.asFileURL()
            }
        }
    }

    init(payload: Payload?, fromAddress: Data? = nil, toAddress: Data? = nil) {
        self.payload = payload
        self.sourceAddress = fromAddress
        self.targetAddress = toAddress
    }
}

extension CKSTask {
    func adapt(using adapter: CKSTaskAdapter?) throws -> CKSTask {
        guard let adapter = adapter else { return self }
        return try adapter.adapt(self)
    }
}


public class CKSUploadTask: CKSTask {
    var countOfBytesPerRead: Int64 = 0

    convenience init(payload: Payload?, fromAddress: Data? = nil, toAddress: Data? = nil, countOfBytesPerRead: Int64) {
        self.init(payload: payload, fromAddress: fromAddress, toAddress: toAddress)
        self.countOfBytesPerRead = countOfBytesPerRead
        if case .file(let file)? = payload {
            expectedContentLength = file.size
        }
    }
}

public class CKSDownloadTask: CKSTask {
    var countOfBytesPerWrite: Int64 = 0
    
    convenience init(payload: Payload?, fromAddress: Data? = nil, toAddress: Data? = nil, countOfBytesPerWrite: Int64) {
        self.init(payload: payload, fromAddress: fromAddress, toAddress: toAddress)
        self.countOfBytesPerWrite = countOfBytesPerWrite
        if case .file(let file)? = payload {
            expectedContentLength = file.size
        }
    }
}






















