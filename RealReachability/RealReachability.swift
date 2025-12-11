//
//  RealReachability.swift
//
//
//  Created by Rex Xing on 2025/9/4.
//

import Foundation
import Network
import Combine

/// 真实连接状态管理
/// 区别于系统框架或者其他三方库只判断是否处于某种网络环境，但实际能否连通是未知的
public class RealReachability: ObservableObject {
    public static let shared = RealReachability()
    
    // MARK: - Private
    
    private var cancelBag = [AnyCancellable]()
    
    /// 本地网络权限状态获取
    private let localAuth = LocalNetworkAuthorization()
    
    /// 外部网络的物理连接状态
    private let environment = InternetEnvironment()
    
    /// 外部网络的HTTP连通检测
    private let httpChecker = InternetHTTPChecker()
    
    // MARK: - Public
    
    /// 外部网络权限 ``在手机[设置]-[App]-[App名称]-[无线数据]中操作改变``
    @Published public private(set) var permission: InternetEnvironment.Permission = .unknown
    
    /// 外部网络的HTTP连通状态 ``这个值代表发起的HTTP请求是否成功``
    @Published public private(set) var isReachable: Bool = true
    
    /// 外部网络环境 例如：wifi, ethernet, cellular ``如果HTTP不通 则为unreachable ``
    @Published public private(set) var status: Status = .unknown
    
    /// 外部蜂窝网络类型 例如：5G, 4G ...
    @Published public private(set) var cellularType: InternetEnvironment.CellularType = .unknown
    
    // MARK: - Init / Deinit
    
    public init() {
        addObservers()
        environment.start()
    }
    
    deinit {
        environment.stop()
        cancelBag.removeAll()
    }
    
    // 监听内部通知传出
    private func addObservers() {
        Publishers.CombineLatest4(
            $isReachable,
            environment.$interfaceType,
            environment.$permission,
            environment.$cellularType
        )
        .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 && $0.2 == $1.2 && $0.3 == $1.3 }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in
            guard let self else { return }
            self.status = $0.1.asStatus($0.0)
            self.permission = $0.2
            self.cellularType = $0.3
            debugLog("[📶RealReachability] Internet status = [\(self.status)] permission = [\($0.2)] cellularType = [\($0.3)] ")
        }.store(in: &cancelBag)
        
        Task {
            await httpChecker.$isReachable
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.isReachable = $0 }
                .store(in: &cancelBag)
        }
    }
    
    // MARK: - Public Function
    
    // 设置检查外部网络状态的域名
    public func setHTTPCheck(urls: [String], timeout: TimeInterval = 2, interval: TimeInterval = 5) {
        Task { await httpChecker.setCheck(urls: urls, timeout: timeout, interval: interval) }
        debugLog("[📶RealReachability] Set HTTPChecker urls = \(urls) timeout = [\(timeout)] interval = [\(interval)] ")
    }

    // 主动获取当前实时外部网络状态
    public func getInternetStatus(completion: ((Bool) -> Void)? = nil) {
        Task { await httpChecker.startCheck(completion) }
    }
    
    /// 获取本地网络权限状态 允许：true 不允许：false
    public func getLocalNetworkAuth(_ completion: @escaping (LocalNetworkAuthorization.Status) -> Void) {
        localAuth.requestAuth { status in
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }
    
    /// VPN使用的接口
    private let vpnInterfaces = ["tap", "tun", "ppp", "ipsec", "utun"]
    
    /// 设备是否开启VPN
    public func isVPNOn() -> Bool {
        guard let dict = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() as? [String: Any],
              let scoped = dict["__SCOPED__"] as? [String: Any] else {
            return false
        }
        for key in scoped.keys {
            for prefix in vpnInterfaces {
                if key.lowercased().contains(prefix) {
                    return true
                }
            }
        }
        return false
    }
    
}

extension RealReachability {
    
    /// 真实连通状态
    public enum Status: String {
        case unknown
        case unreachable
        case wifi
        case ethernet
        case cellular
        
        public var isReachable: Bool {
            switch self {
            case .wifi, .ethernet, .cellular: return true
            default:                          return false
            }
        }
    }
    
}

extension InternetEnvironment.InterfaceType {
    
    func asStatus(_ isReachable: Bool) -> RealReachability.Status {
        guard isReachable else { return .unreachable }
        switch self {
        case .unknown:  return .unknown
        case .wifi:     return .wifi
        case .ethernet: return .ethernet
        case .cellular: return .cellular
        }
    }
    
}

func debugLog(_ message: @autoclosure () -> Any, file: String = #fileID, line: Int = #line) {
#if DEBUG
    print("[\(file):\(line)] \(message())")
#endif
}
