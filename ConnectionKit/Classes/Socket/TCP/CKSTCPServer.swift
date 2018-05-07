//
//  CKSTCPServer.swift
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

public class CKSTCPServer {
    /// A closure executed when monitoring upload or download progress of a request.
    public typealias ProgressHandler = (Progress) -> Void

    let manager = CKSTCPSessionManager()
    var acceptNewSockSubject = PublishSubject<GCDAsyncSocket>()
    var connectSubject = PublishSubject<Bool>()

    public init() {
        manager.delegate.socketDidDisconnect = strongify(weak: self) { (strongSelf, sock, error) in
            let err = CKSTCPError.Client.connectFailed(error: error)
            strongSelf.connectSubject.onError(err)
        }
        manager.delegate.sessionDidAcceptNewSocket = strongify(weak: self, closure: { (strongSelf, sock, newSock) in
            strongSelf.acceptNewSockSubject.onNext(newSock)
        })
    }
    
    func readheader(from sock: GCDAsyncSocket) -> Observable<File?> {
        return Observable.create({ [weak self](observer) -> Disposable in
            guard let strongSelf = self else {
                return Disposables.create()
            }
            strongSelf.manager.request(expectedContentLength: Int64(SocketConstants.TCP.ByteSizeHeader), from: sock)
                .response(completionHandler: { (response) in
                    if let error = response.error {
                        observer.onError(error)
                    } else {
                        var file: File?
                        if let data = response.data {
                            let response = String(data: data, encoding: .utf8)!
                            file = File.init(JSONString: response)
                        }
                        observer.onNext(file)
                        observer.onCompleted()
                    }
                })
            return Disposables.create()
        })
    }
    
    func readThumnail(from sock: GCDAsyncSocket) -> Observable<UIImage?> {
        return Observable.create({ [weak self](observer) -> Disposable in
            guard let strongSelf = self else {
                return Disposables.create()
            }
            strongSelf.manager.request(expectedContentLength: Int64(SocketConstants.TCP.ByteSizeScreenshot), from: sock)
                .response(completionHandler: { (response) in
                    if let error = response.error {
                        observer.onError(error)
                    } else {
                        var image: UIImage?
                        if let data = response.data {
                            image = UIImage(data: data)
                        }
                        observer.onNext(image)
                        observer.onCompleted()
                    }
                })
            return Disposables.create()
        })
    }

    func readBody(to file:File, from sock: GCDAsyncSocket, closure: @escaping ProgressHandler) -> Observable<File> {
        return Observable.create({ [weak self](observer) -> Disposable in
            guard let strongSelf = self else {
                return Disposables.create()
            }
            strongSelf.manager.download(to: file, from: sock, countOfBytesPerWrite: Int64(SocketConstants.TCP.ByteSizeData))
                .progress(closure: closure)
                .response(completionHandler: { (response) in
                    if let error = response.error {
                        observer.onError(error)
                    } else {
                        observer.onNext(file)
                        observer.onCompleted()
                    }
                })
            return Disposables.create()
        })
    }
    

    
    public func start() -> Observable<Bool> {
        do {
            acceptNewSockSubject.dispose()
            acceptNewSockSubject = PublishSubject<GCDAsyncSocket>()
            manager.disconnectAll()
            try manager.accept(onPort: SocketConstants.TCP.ServerPort)
            return Observable.just(true)
        } catch {
            let err = CKSTCPError.Server.startFailed(reason: .tcpSocketError(error: error))
            return Observable.error(err)
        }
    }
    
    public func acceptNewSock() -> Observable<GCDAsyncSocket> {
        return acceptNewSockSubject.observeOn(MainScheduler.asyncInstance)
    }
    
    
    //参考安卓约定，在接受完数据要close sock
    public func read(to file: File, from sock: GCDAsyncSocket, closure: @escaping ProgressHandler) -> Observable<Bool> {
        connectSubject.dispose()
        connectSubject = PublishSubject<Bool>()
        let readObservable = readheader(from: sock)
            .flatMapLatest { [weak self](_) -> Observable<Bool> in
                guard let strongSelf = self else {
                    return Observable.empty()
                }
                
                return strongSelf.readThumnail(from: sock)
                    .flatMapLatest{ (_) -> Observable<Bool> in
                        return Observable.just(true)
                    }
            }.flatMapLatest{ [weak self](_) -> Observable<Bool> in
                guard let strongSelf = self else {
                    return Observable.empty()
                }
                
                return strongSelf.readBody(to: file, from: sock, closure: closure)
                    .flatMapLatest{ (_) -> Observable<Bool> in
                        return Observable.just(true)
                }
            }.do(onNext: { [weak self] (_) in
                self?.connectSubject.onNext(true)
                self?.connectSubject.onCompleted()
            })
        return Observable.combineLatest([self.connectSubject, readObservable]).map({ (_) -> Bool in
            return true
        }).observeOn(MainScheduler.asyncInstance) 
    }
}




















