//
//  InternetReachability.swift
//  
//
//  Created by Rex Xing on 2025/12/10.
//

import Network
import CoreTelephony
import Combine

/// 判断外部网络的设备连接状态
public final class InternetEnvironment: NSObject {

    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "com.reachability.pathmonitor")

    private let telephonyInfo = CTTelephonyNetworkInfo()
    private let telephonyQueue = DispatchQueue(label: "com.reachability.telephonyinfo")
    
    private let cellularData = CTCellularData()
    private let cellularQueue = DispatchQueue(label: "com.reachability.cellularData")

    /// 网络使用权限
    @Published private(set) var permission: Permission = .unknown
    
    /// 网络环境类型
    @Published private(set) var interfaceType: InterfaceType = .unknown
    
    /// 处于蜂窝网络 可获取蜂窝网络类型
    @Published private(set) var cellularType: CellularType = .unknown
    
    deinit {
        stop()
    }

    /// 发起物理连接状态的检查
    public func start() {
        pathMonitor.pathUpdateHandler = { [weak self] in
            self?.pathUpdateHandler($0)
        }
        pathMonitor.start(queue: pathQueue)
        
        telephonyInfo.delegate = self
        
        cellularData.cellularDataRestrictionDidUpdateNotifier = { [weak self] in
            self?.cellularDataUpdateHandler($0)
        }
    }

    public func stop() {
        pathMonitor.cancel()
        
        telephonyInfo.delegate = nil
        
        cellularData.cellularDataRestrictionDidUpdateNotifier = nil
    }
    
    func pathUpdateHandler(_ path: NWPath) {
        pathQueue.async {
            self.interfaceType = path.asInterfaceType
        }
    }
    
    func cellularDataUpdateHandler(_ state: CTCellularDataRestrictedState) {
        cellularQueue.async {
            self.permission = state.asPermission
        }
    }

}

extension InternetEnvironment {
    
    public enum InterfaceType: String {
        case unknown
        case wifi
        case ethernet
        case cellular
    }
    
    public enum Permission: String {
        case unknown
        case restricted
        case allow
    }

    public enum CellularType: String {
        case notfound
        case `5G`
        case `4G`
        case `3G`
        case `2G`
        case unknown
    }
    
}

extension InternetEnvironment: CTTelephonyNetworkInfoDelegate {
    
    public func dataServiceIdentifierDidChange(_ identifier: String) {
        telephonyQueue.async {
            self.cellularType = self.currentCellularType()
        }
    }
    
    func currentCellularType() -> CellularType {
        let techs = telephonyInfo.serviceCurrentRadioAccessTechnology?.values
        guard let tech = techs?.first else { return .notfound }

        switch tech {
        case "CTRadioAccessTechnologyNR",
            "CTRadioAccessTechnologyNRNSA":
            return .`5G`
        case CTRadioAccessTechnologyLTE:
            return .`4G`
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            return .`3G`
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            return .`2G`
        default: return .unknown
        }
    }
    
}

extension CTCellularDataRestrictedState {
    
    var asPermission: InternetEnvironment.Permission {
        switch self {
        case .restrictedStateUnknown:  .unknown
        case .restricted:              .restricted
        case .notRestricted:           .allow
        @unknown default:              .unknown
        }
    }
    
}

extension NWPath {
    
    var asInterfaceType: InternetEnvironment.InterfaceType {
        guard status == .satisfied else { return .unknown }
        if usesInterfaceType(.wifi) {
            return .wifi
        } else if usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if usesInterfaceType(.cellular) {
            return .cellular
        }
        return .unknown
    }
    
}
