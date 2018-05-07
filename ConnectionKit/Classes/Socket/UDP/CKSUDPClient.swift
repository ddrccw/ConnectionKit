//
//  CKSUDPClient.swift
//  ConnectionKit-iOS
//
//  Created by ddrccw on 2018/3/11.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import Foundation
import RxSwift
import Strongify

public class CKSUDPClient {
    let manager = CKSUDPSessionManager()
    var connectSubject = PublishSubject<Bool>()
    var completeSubject: PublishSubject<Bool>?

    public init() {
        manager.delegate.sessionDidConnectToAddress = strongify(weak: self) { (strongSelf, sock, data) in
            print("CKSUDPClient sessionDidConnectToAddress")
            
            strongSelf.connectSubject.onNext(true)
            strongSelf.connectSubject.onCompleted()

        }

        manager.delegate.sessionDidNotConnect = strongify(weak: self) { (strongSelf, sock, error) in
            print("CKSUDPClient sessionDidNotConnect")
            
            let err = CKSUDPError.Client.connectFailed(error: error)
            strongSelf.connectSubject.onError(err)
        }

        manager.delegate.sessionDidReceiveData = strongify(weak: self) { (strongSelf, sock, data, fromAddress, filterContext) in
            let response = String(data: data, encoding: .utf8)!
            if response == SocketConstants.MessageFinish, let completeSubject = strongSelf.completeSubject  {
                strongSelf.manager.close()
                completeSubject.onNext(true)
                completeSubject.onCompleted()
            }
        }
    }

    public func connect(toServer address: Data) -> Observable<Bool> {
        //连接是否成功和对方是否开启server服务无关
        if !manager.isConnected() {
            connectSubject.dispose()
            connectSubject = PublishSubject<Bool>()
            //connect的线程比主线程的处理快，要保证注册好监听后再connect
            return Observable.just(true)
                .flatMapLatest { [weak self] (x) -> Observable<Bool> in
                    guard let strongSelf = self else {
                        return Observable.empty()
                    }
                
                    try strongSelf.manager.connect(to: address)
                    return strongSelf.connectSubject.observeOn(MainScheduler.asyncInstance)
                }.catchError({ (e) -> Observable<Bool> in
                    let err = CKSUDPError.Client.connectFailed(error: e)
                    return Observable.error(err)
                })
        } else {
            return Observable.just(true)
        }
    }
    
    public func send(file: File) -> Observable<CKSTask?> {
        return Observable.create({[weak self](observer) -> Disposable in
            guard let strongSelf = self else {
                return Disposables.create()
            }
            strongSelf.manager.request(payload: .file(file)).response(completionHandler: { (response) in
                if let error = response.error {
                    observer.on(.error(error))
                } else {
                    observer.on(.next(response.task))
                    observer.on(.completed)
                }
            })
            return Disposables.create()
        })
    }
    
    public func send(fileList: [File]) -> Observable<Bool> {
        var observables: [Observable<CKSTask?>] = []
        var sendedFileInfo: [File] = []
        for file in fileList {
            let observable = send(file: file).map({ (task) -> CKSTask? in
                sendedFileInfo.append(file)
                return task
            }).catchError({ (e) -> Observable<CKSTask?> in
                Observable.error(CKSUDPError.Client.transferFileFailed(error: e))
            })
            
            observables.append(observable)
        }
        
        return Observable.zip(observables).flatMapLatest{ [weak self](tasks) -> Observable<Bool> in
            guard let strongSelf = self else {
                return Observable.empty()
            }

            if tasks.count == sendedFileInfo.count {
                //send complete
                try strongSelf.manager.beginReceiving()
                return strongSelf.sendFinishToServer().flatMapLatest({ [weak self](task) -> Observable<Bool> in
                    guard let strongSelf = self else {
                        return Observable.empty()
                    }
                    strongSelf.completeSubject?.dispose()
                    strongSelf.completeSubject = PublishSubject<Bool>()
                    return strongSelf.completeSubject!.observeOn(MainScheduler.asyncInstance)
                })
            } else {
                return Observable.error(CKSUDPError.Client.transferFileFailed(error: nil))
            }
        }
    }    

    //发送文件列表信息后，通知服务端发送完了
    func sendFinishToServer() -> Observable<CKSTask?> {
        return Observable.create({ [weak self](observer) -> Disposable in
            guard let strongSelf = self else {
                return Disposables.create()
            }
            strongSelf.manager.request(payload: .text(SocketConstants.MessageFinish)).response(completionHandler: { (response) in
                if let error = response.error {
                    observer.on(.error(error))
                } else {
                    observer.on(.next(response.task))
                    observer.on(.completed)
                }
            })
            return Disposables.create()
        })
    }
}
