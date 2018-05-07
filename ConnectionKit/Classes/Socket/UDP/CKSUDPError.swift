//
//  CKSUDPError.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/11.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public enum CKSUDPError: Error {
    public enum Server {
        
        public enum StartFailureReason: LocalizedError {
            case udpSocketError(error: Error)
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

}

// MARK: - Adapt Error

struct CKSUDPAdaptError: Error {
    let error: Error
}

//extension Error {
//    var underlyingAdaptError: Error? { return (self as? CKSUDPAdaptError)?.error }
//}

// MARK: - Error Descriptions

extension CKSUDPError.Server: LocalizedError {
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


extension CKSUDPError.Server.StartFailureReason {
    var localizedDescription: String {
        switch self {
        case .udpSocketError(let error):
            return error.localizedDescription
        }
    }
}


extension CKSUDPError.Client: LocalizedError {
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



