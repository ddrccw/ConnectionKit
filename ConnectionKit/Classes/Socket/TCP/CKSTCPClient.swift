//
//  CKSTCPClient.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/4/1.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxSwiftExt
import CocoaAsyncSocket
import Strongify

public class CKSTCPClient {
    /// A closure executed when monitoring upload or download progress of a request.
    public typealias ProgressHandler = (Progress) -> Void
    let manager = CKSTCPSessionManager()
    var connectSubject = PublishSubject<Bool>()
    
    public init() {
        manager.delegate.socketDidDisconnect = strongify(weak: self) { (strongSelf, sock, error) in
            let err = CKSTCPError.Client.connectFailed(error: error)
            strongSelf.connectSubject.onError(err)
        }
    }

    func sendHeader(with file: File) -> Observable<Bool> {
        return Observable.create({ [weak self](observer) -> Disposable in
            guard let strongSelf = self else {
                return Disposables.create()
            }
            
            do {
                var data = try file.asData()
                let left = SocketConstants.TCP.ByteSizeHeader - UInt64(data.count)
                let space = [UInt8](repeating: 0, count: Int(left))
                data.append(contentsOf: space)
                strongSelf.manager.request(payload: .data(data)).response(completionHandler: { (response) in
                    if let error = response.error {
                        observer.onError(error)
                    } else {
                        observer.onNext(true)
                        observer.onCompleted()
                    }
                })
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        })
    }
    
    func sendThumbnail(with file: File) -> Observable<Bool> {
        return Observable.create({ [weak self](observer) -> Disposable in
            guard let strongSelf = self else {
                return Disposables.create()
            }
            //TODO: imagepath
            var data = Data()
            var left = SocketConstants.TCP.ByteSizeScreenshot
            if let image = UIImage(contentsOfFile: file.filePath!) {
                let thumbnailSize = CGSize(width: 96, height: 96)
                UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, UIScreen.main.scale)
                image.draw(in: CGRect(origin: CGPoint.zero, size: thumbnailSize))
                let thumbnaimImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                let thumbnailData = UIImagePNGRepresentation(thumbnaimImage!)!
                left = left - UInt64(thumbnailData.count)
                data.append(thumbnailData)
                if left < SocketConstants.TCP.ByteSizeScreenshot {
                    let space = [UInt8](repeating: 0, count: Int(left))
                    data.append(contentsOf: space)
                } else {
                    data = data.prefix(Int(SocketConstants.TCP.ByteSizeScreenshot))
                }
            } else {
                let space = [UInt8](repeating: 0, count: Int(left))
                data.append(contentsOf: space)
            }

            strongSelf.manager.request(payload: .data(data)).response(completionHandler: { (response) in
                if let error = response.error {
                    observer.onError(error)
                } else {
                    observer.onNext(true)
                    observer.onCompleted()
                }
            })
            return Disposables.create()
        })
    }
    
    func sendBody(with file: File, closure: @escaping ProgressHandler) -> Observable<Bool> {
        return Observable.create({ [weak self](observer) -> Disposable in
            guard let strongSelf = self else {
                return Disposables.create()
            }
            strongSelf.manager.upload(file, countOfBytesPerRead: Int64(SocketConstants.TCP.ByteSizeData))
                .progress(closure: closure)
                .response(completionHandler: { (response) in
                    if let error = response.error {
                        observer.onError(error)
                    } else {
                        observer.onNext(true)
                        observer.onCompleted()
                    }
                })
            return Disposables.create()
        })
    }

    public func send(file: File, to address: Data, closure: @escaping ProgressHandler) -> Observable<Bool> {
        do {
            if !manager.isConnected() {
                try manager.connect(to: address)
            }
        } catch {
            let err = CKSTCPError.Client.connectFailed(error: error)
            return Observable.error(err)
        }
        //0.发送 即将发送的文件信息
        connectSubject.dispose()
        connectSubject = PublishSubject()
        let observable = sendHeader(with: file)
            .flatMapLatest ({ [weak self] _ -> Observable<Bool> in
                //1.发送 即将发送的文件缩略图
                guard let strongSelf = self else {
                    return Observable.empty()
                }
                return strongSelf.sendThumbnail(with: file)
            }).flatMapLatest ({ [weak self] _ -> Observable<Bool> in
                //2. 发送 文件
                guard let strongSelf = self else {
                    return Observable.empty()
                }
                return strongSelf.sendBody(with: file, closure: closure)
            }).do(onNext: { [weak self] (_) in
                self?.connectSubject.onNext(true)
                self?.connectSubject.onCompleted()
            }).catchError { (e) -> Observable<Bool> in
                let err = CKSTCPError.Client.transferFileFailed(error: e)
                return Observable.error(err)
        }
        return Observable.combineLatest([self.connectSubject, observable])
                         .flatMapLatest({ (_) -> Observable<Bool> in
            return Observable.just(true)
        }).observeOn(MainScheduler.asyncInstance) 
    }
}























