//
//  CKSUDPNotifications.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/11.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation

extension Notification.Name {
    public struct ServerState {
        public static let DidChange = Notification.Name(rawValue: "connectionkit.notification.name.serverState.didChanage")
    }
}
