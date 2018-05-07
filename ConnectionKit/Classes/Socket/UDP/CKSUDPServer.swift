//
//  CKSUDPServer.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/11.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import RxSwift
import CocoaAsyncSocket
import Strongify

//typedef NS_ENUM(NSUInteger, YKFCKUDPReceiverServerState) {
//    YKFCKUDPReceiverServerStateUnknown,
//    YKFCKUDPReceiverServerStateBindPortFailed,
//    YKFCKUDPReceiverServerStateBeginReceivingFailed,
//    YKFCKUDPReceiverServerStateFileInfoReceived
//};


public class CKSUDPServer {
    
    let manager = CKSUDPSessionManager()
    var receivedFromAddresses = [Data: [File]]()
    var startServerCompleteSubject = PublishSubject<(Array<File>, Data)>()
    
    public init() {
        manager.delegate.sessionDidConnectToAddress = { (sock, data) in
            print("CKSUDPSessionManager sessionDidConnectToAddress")
        }
        
        manager.delegate.sessionDidNotConnect = strongify(weak: self) { (strongSelf, sock, error) in
            let err = CKSUDPError.Server.connectFailed(error: error)
            strongSelf.startServerCompleteSubject.onError(err)
        }
        
        manager.delegate.sessionDidReceiveData = strongify(weak: self) { (strongSelf, sock, data, fromAddress, filterContext) in
            var fileList = strongSelf.receivedFromAddresses[fromAddress]
            if fileList == nil {
                fileList = []
            }
            
            let response = String(data: data, encoding: .utf8)!
            if response == SocketConstants.MessageFinish {
                //收到文件列表信息，但是暂时未通知客户端开始传送
                strongSelf.startServerCompleteSubject.onNext((fileList!, fromAddress))
                strongSelf.startServerCompleteSubject.onCompleted()
            } else {
                if let file = File(JSONString: response) {
                    fileList!.append(file)
                    strongSelf.receivedFromAddresses[fromAddress] = fileList
                }
            }
        }
    }
    
    public func start() -> Observable<(Array<File>, Data)> {
        manager.close()
        startServerCompleteSubject.dispose()
        startServerCompleteSubject = PublishSubject<(Array<File>, Data)>()
        //socket的线程比主线程的处理快，要保证注册好监听后再bind
        return Observable.just(true)
            .flatMap { [weak self] (x) -> Observable<(Array<File>, Data)> in
                guard let strongSelf = self else {
                    return Observable.empty()
                }
                
                try strongSelf.manager.bind(port: SocketConstants.UDP.ServerPort)
                try strongSelf.manager.beginReceiving()
                return strongSelf.startServerCompleteSubject.observeOn(MainScheduler.asyncInstance)
            }.catchError({ (error) -> Observable<(Array<File>, Data)> in
                let err = CKSUDPError.Server.startFailed(reason: .udpSocketError(error: error))
                return Observable.error(err)
            })
    }
    
    //收到文件列表信息后，通知客户端可以开始传送文件
    public func sendFinish(toClient address: Data) -> Observable<Bool> {
        return Observable.create({ [weak self](observer) -> Disposable in
            guard let strongSelf = self else {
                return Disposables.create()
            }
            strongSelf.manager
                .request(payload: .text(SocketConstants.MessageFinish), to: address)
                .response(completionHandler: { (response) in
                if let error = response.error {
                    observer.on(.error(error))
                } else {
                    observer.on(.next(true))
                    observer.on(.completed)
                }
            })
            return Disposables.create()
        })
    }
}























