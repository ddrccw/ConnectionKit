//
//  ViewController.swift
//  ConnectionKit-Demo
//
//  Created by ddrccw on 2018/2/3.
//  Copyright © 2018年 ddrccw. All rights reserved.
//

import UIKit
import ConnectionKit
import MBProgressHUD
import CocoaAsyncSocket
import RxSwift
import RxSwiftExt
import AVFoundation
import AVKit


import Alamofire


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    let label = UILabel(frame: CGRect.zero)
    let data = [
        ["Multipeer Connectivity":
         [
//            ["testSearch", "搜索"],
//            ["testSend", "发送"],
//            ["testReceive", "接收"], // @"接收"
//            
//            ["send", "接收"], // @"接收"
//            
//            
            ]
        ],
        ["socket":
         [
            ["testSocketSend", "发送"], // @"发送"
            ["testSocketReceive", "接收"], // @"接收"
            ]
        ]
    ]
    
    let udpClient = CKSUDPClient()
    let udpServer = CKSUDPServer()
    let tcpClient = CKSTCPClient()
    let tcpServer = CKSTCPServer()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        UIApplication.shared.isIdleTimerDisabled = true
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.reloadData()
        label.numberOfLines = 0;
        
        /*
         建立热点的设备
         2017-09-06 11:54:25.197539+0800 YKMainClient[3480:2061044] gateway=(null)
         2017-09-06 11:54:25.198561+0800 YKMainClient[3480:2061044] ip=172.20.10.1
         
         连接热点的设备
         2017-09-06 11:54:57.790325+0800 YKMainClient[5098:1808213] gateway=172.20.10.1
         2017-09-06 11:54:57.790441+0800 YKMainClient[5098:1808213] ip=172.20.10.2
         */
        debugPrint("gateway=\(String(describing: SocketUtils.getGatewayIP()))")
        debugPrint("ip=\(String(describing: SocketNetCoreUtils.getIpAddress()))")
        _ = SocketUtils.getARPTableInfo()
        
        let testFilePath = Bundle.main.path(forResource: "test", ofType: "mp4")
        var file = File(filePath: testFilePath!, fileType: .MP4)
        debugPrint("md5=\(String(describing: file?.md5)), length=\(String(describing: file?.md5?.count))")
        debugPrint("currentDevice=\(UIDevice.current.name)")
        
//        Alamofire.request("https://httpbin.org/get").responseJSON { response in
//            print("Request: \(String(describing: response.request))")   // original url request
//            print("Response: \(String(describing: response.response))") // http url response
//            print("Result: \(response.result)")                         // response serialization result
//
//            if let json = response.result.value {
//                print("JSON: \(json)") // serialized json response
//            }
//
//            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
//                print("Data: \(utf8Text)") // original server data as UTF8 string
//            }
//        }
    }

    func show(text: String) {
        var hud = MBProgressHUD(for: view)
        if hud == nil {
            hud = MBProgressHUD.showAdded(to: view, animated: true)
        }
        hud?.isUserInteractionEnabled = false
        hud?.detailsLabel.text = text
        debugPrint(text)
        label.text = text;
    }

    func hideHud() {
        let hud = MBProgressHUD(for: view)
        hud?.hide(animated: true, afterDelay: 1)
    }

    func showAndHide(text: String) {
        show(text: text)
        hideHud()
    }
    
    func handleReceivedFileWithFileInfo(file: File, localFile: File) {
        showAndHide(text: "tcpServer readSignalToFile=\(String(describing: localFile.filePath)) complete")
        do {
            guard let filePath = localFile.filePath else {
                return
            }
            let attribute = try FileManager.default.attributesOfItem(atPath: filePath)
            debugPrint("testSocketReceive complete=\(String(describing: filePath)), size=\(String(describing: attribute[FileAttributeKey.size]))")
            
            let alert = UIAlertController()
            alert.message = "文件(\(file))传输成功，是否允许播放"
            let playAction = UIAlertAction(title: "播放", style: .default) { (_) in
                let fileURL = URL(fileURLWithPath: filePath)
                let player = AVPlayer(url: fileURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                player.play() //Used to Play On start
                self.present(playerViewController, animated: true, completion: nil)
            }
            alert.addAction(playAction)
            let cancelAction = UIAlertAction(title: "不播放", style: .cancel) { [weak alert](_) in
                alert?.dismiss(animated: true, completion: nil)
            }
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        } catch {
            
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // MARK: table view data source && delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (data[section].first?.value.count)!
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data[section].keys.first
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let title = data[indexPath.section].values.first![indexPath.row][1]
        cell?.textLabel?.text = title
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selStr = data[indexPath.section].values.first![indexPath.row][0]
        let sel = NSSelectorFromString(selStr)
        self.perform(sel)
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        label.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height / 3.0)
        return label;
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    // MARK: socket
    @objc
    func testSocketSend() -> Void {
        hideHud()
        
        guard let testFilePath = Bundle.main.path(forResource: "test", ofType: "mp4") else {
            return
        }
        
        guard FileManager.default.fileExists(atPath: testFilePath) else {
            return
        }
        //Sequence
        //AnySequence
        guard HotspotManager.default.isReachable() else {
            showAndHide(text: "is not reachable!!")
            return
        }

        do {
            guard var file = File(filePath: testFilePath, fileType: .MP4) else {
                return
            }
            let attribute = try FileManager.default.attributesOfItem(atPath: testFilePath)
            file.size = attribute[FileAttributeKey.size] as! Int64
            
            //建立热点的设备
            var serverAddr: Data
            if HotspotManager.default.isHotspot() {
                serverAddr = SocketUtils.getARPTableInfo()![0]
                serverAddr = SocketUtils.getAddressData(address: serverAddr, port: SocketConstants.UDP.ServerPort)
            } else {  //连接热点的设备
                serverAddr = SocketUtils.getGatewayInfoData(port: SocketConstants.UDP.ServerPort)!
            }
            
            let isIp4 = GCDAsyncSocket.isIPv4Address(serverAddr)
            let host = GCDAsyncSocket.host(fromAddress: serverAddr)
            let port = GCDAsyncSocket.port(fromAddress: serverAddr)
            debugPrint("udp server isIp4=\(isIp4), host(\(String(describing: host)):\(port))")
            
            //1. upd client connect to server
            let clientObservable = udpClient.connect(toServer: serverAddr)
                .flatMapLatest({ [weak self](_) -> Observable<Bool> in
                    guard let strongSelf = self else {
                        return Observable.empty()
                    }
                    
                    //return Observable.just(true)

                    strongSelf.show(text: "udpClient connectToServer")
                    //2. upd client send fileinfo & finish to server
                    return strongSelf.udpClient.send(fileList: [file])
                }).flatMapLatest({ [weak self](_) -> Observable<Bool> in
                    guard let strongSelf = self else {
                        return Observable.empty()
                    }
                    
                    //return Observable.just(true)
                    
                    strongSelf.show(text: "self.tcpClient sendSignalWithfileInfo=\(file)")

                    //4. tcp client send fileinfo(header+thumbnail+body)
                    serverAddr = SocketUtils.getAddressData(address: serverAddr, port: SocketConstants.TCP.ServerPort)
                    let isIp4 = GCDAsyncSocket.isIPv4Address(serverAddr)
                    let host = GCDAsyncSocket.host(fromAddress: serverAddr)
                    let port = GCDAsyncSocket.port(fromAddress: serverAddr)
                    debugPrint("tcp server isIp4=\(isIp4), host(\(String(describing: host)):\(port))")
                    return strongSelf.tcpClient.send(file: file, to: serverAddr, closure: { [weak self](progress) in
                        self?.show(text: "send progress=\(progress.fractionCompleted)")
                    })
            })
            
            clientObservable.flatMap({ (x) -> Observable<Bool> in
                return Observable.just(true)
            }).subscribe(onNext: { [weak self] (x) in
                self?.showAndHide(text: "send success");
                debugPrint(x)
            }, onError: { [weak self] (e) in
                self?.showAndHide(text: "send failure");
                debugPrint(e)
            }, onCompleted: {
                debugPrint("complete")
            }).disposed(by: disposeBag)
        } catch {
            debugPrint(error)
        }
    }
    
    @objc
    func testSocketReceive() -> Void {
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let targetUrl = documentPath + "/lalal.mp4"
        
        do {
            if FileManager.default.fileExists(atPath: targetUrl) {
                let attribute = try FileManager.default.attributesOfItem(atPath: targetUrl)
                try FileManager.default.removeItem(atPath: targetUrl)
                debugPrint("testSocketReceive exist=\(targetUrl), size=\(String(describing: attribute[FileAttributeKey.size]))")
            } else {
//                let data = try "blank".asData()
//                let x = FileManager.default.createFile(atPath: targetUrl, contents: data, attributes: nil)
//                
//                
//                if FileManager.default.fileExists(atPath: targetUrl) {
//                    debugPrint("wwwwww")
//                }
            }
            
            
            //0. start udp & tcp server and wait file info
            let udpServerStartObservable = udpServer.start().do(onNext: { [weak self] value in
                self?.show(text: "udpServer startServerSignal fileList=\(value)")
            }).catchError({ [weak self] (err) -> Observable<(Array<File>, Data)> in
                self?.show(text: "udpServer startServerSignal error=\(err)")
                return Observable.error(err)
            })
            let tcpServerStartObservable = tcpServer.start().do(
                onNext: { [weak self] v in
                    self?.show(text: "tcpServer startServerSignal socks=\(v)")
                }, onError: { [weak self](err) in
                    self?.show(text: "tcpServer startServerSignal error=\(err)")
            })
            
            udpServerStartObservable.zip(with: tcpServerStartObservable) { [weak self](x, _) -> Void in
                guard let strongSelf = self else {
                    return
                }

                let (receivedFileInfoList, address) = x
                let file = receivedFileInfoList[0]
                
                let isIp4 = GCDAsyncSocket.isIPv4Address(address)
                let host = GCDAsyncSocket.host(fromAddress: address)
                let port = GCDAsyncSocket.port(fromAddress: address)
                debugPrint("udp client isIp4=\(isIp4), host(\(String(describing: host)):\(port))")
                
                //3. udp server send finish to client & accept tcp sock
                //收到文件列表信息后，通知客户端可以开始传送文件
                let udpFinishObservable = strongSelf.udpServer.sendFinish(toClient: address).do(
                    onNext:{ [weak self](_) in
                        self?.show(text: "udpServer sendFinishToClientSignal")
                    }, onError: { [weak self] err in
                        self?.show(text: "udpServer sendFinishToClientSignal error=\(err)")
                })
                let tcpAcceptObservable = strongSelf.tcpServer.acceptNewSock().do(onNext:{ [weak self](_) in
                    self?.show(text: "tcpServer acceptNewSock")
                    }, onError: { [weak self] err in
                        self?.show(text: "tcpServer acceptNewSock error=\(err)")
                })
                
                udpFinishObservable.zip(with: tcpAcceptObservable) { [weak self] (_, sock) in
                    //5. tcp server read fileinfo(header+thumbnail+body) & disconnect from sock
                    guard let strongSelf = self else {
                        return
                    }

                    var localFile = file
                    localFile.filePath = targetUrl
                    strongSelf.tcpServer.read(to: localFile, from: sock, closure: { [weak self](progress) in
                        self?.show(text: "receive progress=\(progress.fractionCompleted)")
                    }).subscribeCompleted(weak: strongSelf, { (strongSelf) -> () -> Void in
                        return {
                            strongSelf.handleReceivedFileWithFileInfo(file: file, localFile: localFile)
                        }
                    }).disposed(by: strongSelf.disposeBag)
                }.subscribe().disposed(by: strongSelf.disposeBag)
            }.subscribe().disposed(by: disposeBag)

        } catch  {
            debugPrint(error)
        }
    }
}

















