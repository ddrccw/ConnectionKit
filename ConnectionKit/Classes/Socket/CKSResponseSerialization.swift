//
//  CKSResponseSerialization.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/19.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation

extension CKSRequest {
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:             The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    @discardableResult
    public func response(queue: DispatchQueue? = nil, completionHandler: @escaping (CKSDefaultDataResponse) -> Void) -> Self {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                let dataResponse = CKSDefaultDataResponse(
                    task: self.task,
                    data: self.delegate.data,
                    error: self.delegate.error
                )

//                dataResponse.add(self.delegate.metrics)

                completionHandler(dataResponse)
            }
        }
        
        return self
    }

}
