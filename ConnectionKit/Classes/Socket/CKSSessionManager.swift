//
//  CKSSessionManager.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/4/7.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

protocol CKSSessionManagerProtocol: class {
    associatedtype Request
    func request(payload: CKSTask.Payload?, to address: Data?) -> Request
}


