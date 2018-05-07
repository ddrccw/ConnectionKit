//
//  FileInfo.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/2/25.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import UIKit
import CommonCrypto
import ObjectMapper

extension String {
    func md5() -> String! {
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}

public enum FileType: UInt {
    case JPG = 2
    case MP3
    case MP4
}

public struct File: Mappable {
    
    public var filePath: String?
    public var fileType: FileType!
    public var size: Int64!
    
    private var _md5: String?
    public lazy var md5: String? = {
        if _md5 == nil {
            let string = "\(filePath ?? "")_\(fileType)"
            _md5 = string.md5()
        }
        return _md5
    }()
    
    public init?(filePath: String, fileType: FileType, size: Int64 = 0) {
        self.filePath = filePath
        self.fileType = fileType
        self.size = size
    }

    public init?(map: Map) {
        
    }

    // Mappable
    public mutating func mapping(map: Map) {
        filePath <- map["filePath"]
        fileType <- (map["fileType"], EnumTransform())
        size     <- map["size"]
        _md5     <- map["md5"]
    }
    

}
