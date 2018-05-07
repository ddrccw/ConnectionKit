//
//  CKSTCPError.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/4/6.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public enum CKSTCPError: Error {
    /// The underlying reason the multipart encoding error occurred.
    ///
    /// - bodyPartURLInvalid:                   The `fileURL` provided for reading an encodable body part isn't a
    ///                                         file URL.
    /// - bodyPartFilenameInvalid:              The filename of the `fileURL` provided has either an empty
    ///                                         `lastPathComponent` or `pathExtension.
    /// - bodyPartFileNotReachable:             The file at the `fileURL` provided was not reachable.
    /// - bodyPartFileNotReachableWithError:    Attempting to check the reachability of the `fileURL` provided threw
    ///                                         an error.
    /// - bodyPartFileIsDirectory:              The file at the `fileURL` provided is actually a directory.
    /// - bodyPartFileSizeNotAvailable:         The size of the file at the `fileURL` provided was not returned by
    ///                                         the system.
    /// - bodyPartFileSizeQueryFailedWithError: The attempt to find the size of the file at the `fileURL` provided
    ///                                         threw an error.
    /// - bodyPartInputStreamCreationFailed:    An `InputStream` could not be created for the provided `fileURL`.
    /// - outputStreamCreationFailed:           An `OutputStream` could not be created when attempting to write the
    ///                                         encoded data to disk.
    /// - outputStreamFileAlreadyExists:        The encoded body data could not be writtent disk because a file
    ///                                         already exists at the provided `fileURL`.
    /// - outputStreamURLInvalid:               The `fileURL` provided for writing the encoded body data to disk is
    ///                                         not a file URL.
    /// - outputStreamWriteFailed:              The attempt to write the encoded body data to disk failed with an
    ///                                         underlying error.
    /// - inputStreamReadFailed:                The attempt to read an encoded body part `InputStream` failed with
    ///                                         underlying system error.
    public enum MultipartEncodingFailureReason {
        case bodyPartURLInvalid(url: URL)
        case bodyPartFilenameInvalid(in: URL)
        case bodyPartFileNotReachable(at: URL)
        case bodyPartFileNotReachableWithError(atURL: URL, error: Error)
        case bodyPartFileIsDirectory(at: URL)
        case bodyPartFileSizeNotAvailable(at: URL)
        case bodyPartFileSizeQueryFailedWithError(forURL: URL, error: Error)
        case bodyPartInputStreamCreationFailed(for: URL)
        
        case outputStreamCreationFailed(for: URL)
        case outputStreamFileAlreadyExists(at: URL)
        case outputStreamURLInvalid(url: URL)
        case outputStreamWriteFailed(error: Error)
        
        case inputStreamReadFailed(error: Error)
    }

    public enum Server {
        
        public enum StartFailureReason: LocalizedError {
            case tcpSocketError(error: Error)
        }
        
        case unknown(error: Error?)
        case startFailed(reason: StartFailureReason)
        case beginReceivingFailed(error: Error)
        case connectFailed(error: Error?)
    }
    
    public enum Client {
        case unknown(error: Error?)
        case bindPortFailed(error: Error)
        case beginReceivingFailed(error: Error)
        case connectFailed(error: Error?)
        case transferFileFailed(error: Error?)
    }
    
    case invalidPayload(payload: PayloadConvertible)
    case multipartEncodingFailed(reason: MultipartEncodingFailureReason)
    case dataUploadFailed(error: Error?)
    case dataDownloadFailed(error: Error?)
}

// MARK: - Adapt Error

struct CKSTCPAdaptError: Error {
    let error: Error
}

//extension Error {
//    var underlyingAdaptError: Error? { return (self as? CKSTCPAdaptError)?.error }
//}

// MARK: - Error Descriptions

extension CKSTCPError.Server: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .startFailed(let reason):
            return reason.localizedDescription
        case .unknown(let error):
            return error?.localizedDescription
        case .beginReceivingFailed(let error):
            return error.localizedDescription
        case .connectFailed(let error):
            return error?.localizedDescription
        }
    }
}


extension CKSTCPError.Server.StartFailureReason {
    var localizedDescription: String {
        switch self {
        case .tcpSocketError(let error):
            return error.localizedDescription
        }
    }
}


extension CKSTCPError.Client: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknown(let error):
            return error?.localizedDescription
        case .bindPortFailed(let error):
            return error.localizedDescription
        case .beginReceivingFailed(let error):
            return error.localizedDescription
        case .connectFailed(let error):
            return error?.localizedDescription
        case .transferFileFailed(let error):
            return error?.localizedDescription
        }
    }
}
