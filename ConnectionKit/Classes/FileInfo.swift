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
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating:0, count:Int(CC_MD5_DIGEST_LENGTH))
//        CC_MD5_Init(context)
//        CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
//        CC_MD5_Final(&digest, context)
        context.deallocate(capacity: 1)
        var hexString = ""
        for byte in digest {
            hexString += String(format:"%02x", byte)
        }
        
//        return hexString

//        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
//        _ = digestData.withUnsafeMutableBytes {digestBytes in
//            messageData.withUnsafeBytes {messageBytes in
//                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
//            }
//        }
        
//        return digestData

        return ""
    }
}

enum FileInfoFileType {
    case JPG
    case MP3
    case MP4
}

class FileInfo: Mappable {
    var filePath: String?
    var fileType: FileInfoFileType!
    var size: Int64!
    
    private var _md5: String?
    lazy var md5: String? = {
        if _md5 != nil {
            let string = "\(filePath ?? "")_\(fileType)"
            let originalStr = string.utf8CString
            _md5 = string.md5()
            
        }
        return _md5
    }()
    
    
    required init?(map: Map) {
        
    }
    
    // Mappable
    func mapping(map: Map) {
    }

}
