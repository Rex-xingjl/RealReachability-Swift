//
//  LocalNetworkAuthorization.swift
//  
//
//  Created by Rex Xing on 2025/12/10.
//

import Foundation
import Network

/// ** 需要申请 Multicast Networking Entitlement 才能使用该权限 **
/// https://developer.apple.com/contact/request/networking-multicast
///
/// 本地网络连接权限的监听
/// https://stackoverflow.com/questions/63940427/ios-14-how-to-trigger-local-network-dialog-and-check-user-answer

public final class LocalNetworkAuthorization: NSObject {
    typealias CallBack = (Status) -> Void
     
    public enum Status {
        case appNoAuth // App未申请Multicast
        case allow     // 允许本地权限
        case denied    // 不允许本地权限
    }
    
    private var callbacks: [CallBack?] = []
    private var checking: Bool = false
    
    private var browser: NWBrowser?
    private var netService: NetService?
    private var completion: ((Bool) -> Void)?
    
    /// 请求本地网络权限
    func requestAuth(_ completion: CallBack? = nil) {
        callbacks.append(completion)
        guard !checking else { return }
        checking = true
        
        // Create parameters, and allow browsing over peer-to-peer link.
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        // Browse for a custom service type.
        browser = NWBrowser(for: .bonjour(type: "_bonjour._tcp", domain: nil), using: parameters)
        browser?.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .failed(let error):
                debugLog("[📶RealReachability] Local network permission error = \(error.localizedDescription). You need to add `Multicast Networking Entitlement` for you app. View in https://developer.apple.com/contact/request/networking-multicast .")
                self?.finish(with: .appNoAuth)
            case let .waiting(error):
                debugLog("[📶RealReachability] Local network permission has been denied: \(error)")
                self?.finish(with: .denied)
            default:
                break
            }
        }
        
        netService = NetService(domain: "local.", type:"_lnp._tcp.", name: "LocalNetworkPrivacy", port: 1100)
        netService?.delegate = self
        
        browser?.start(queue: .main)
        netService?.publish()
    }
    
    private func finish(with status: Status) {
        let callCache = callbacks
        callbacks = []
        callCache.forEach { $0?(status) }
        
        browser?.cancel()
        browser = nil
        netService?.stop()
        netService = nil
        checking = false
    }
    
}

@available(iOS 14.0, *)
extension LocalNetworkAuthorization : NetServiceDelegate {
    
    public func netServiceDidPublish(_ sender: NetService) {
        debugLog("[📶RealReachability] Local network permission has been granted")
        finish(with: .allow)
    }
    
}
