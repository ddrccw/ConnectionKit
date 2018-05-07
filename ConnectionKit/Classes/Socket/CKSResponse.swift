//
//  CKSResponse.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/19.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation

/// Used to store all data associated with an non-serialized response of a data or upload request.
struct CKSDefaultDataResponse {
    /// The task sent to the server.
    let task: CKSTask?
    
    /// The data returned by the server.
    public let data: Data?
    
    /// The error encountered while executing or validating the request.
    public let error: Error?
    
    /// Creates a `DefaultDataResponse` instance from the specified parameters.
    ///
    /// - Parameters:
    ///   - request:  The URL request sent to the server.
    ///   - data:     The data returned by the server.
    ///   - error:    The error encountered while executing or validating the request.
    public init(
        task: CKSTask?,
        data: Data?,
        error: Error?)
    {
        self.task = task
        self.data = data
        self.error = error
    }
}
