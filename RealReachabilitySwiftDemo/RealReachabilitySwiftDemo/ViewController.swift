//
//  ViewController.swift
//  RealReachabilitySwiftDemo
//
//  Created by Rex Xing on 2025/12/11.
//

import UIKit
import Combine
import SwiftUI

/// 在UIKit场景下使用
class ViewController: UIViewController {
    
    private var cancelBag = [AnyCancellable]()

    @IBOutlet weak var iconImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImageView.layer.cornerRadius = 16
        iconImageView.layer.masksToBounds = true
        
        realReachabilityTest()
    }
    
    func realReachabilityTest() {
        /// 设置检测的域名地址 一般从数据中拿到的都是字符串 所以这里不要求传URL
        RealReachability.shared.setHTTPCheck(urls: ["https://www.apple.com"],
                                             timeout: 2,
                                             interval: 5)
       
        /// 🛜实时网络状态 1. 能连通则为所处连接环境： wifi、cellular等  2. 否则为unreachable
        RealReachability.shared.$status
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { debugLog(" RealReachability - internet status = \($0)") }
            .store(in: &cancelBag)
        
        /// 🟢无限网络权限
        RealReachability.shared.$permission
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { debugLog(" RealReachability - internet permission = \($0)") }
            .store(in: &cancelBag)
        
        /// 📶蜂窝网络环境
        RealReachability.shared.$cellularType
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { debugLog(" RealReachability - internet cellularType = \($0)") }
            .store(in: &cancelBag)
        
        /// ✅也可以只判断是否能连通外网，不关注所处网络环境
        RealReachability.shared.$isReachable
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { debugLog(" RealReachability - internet isReachable = \($0)") }
            .store(in: &cancelBag)
    
        /// 可以随时主动获取 会返回下一轮次的结果
        RealReachability.shared.getInternetStatus {
            debugLog(" RealReachability - get internet status = \($0)")
        }
        
        /// 获取本地网络权限 用于投屏之类的场景
        RealReachability.shared.getLocalNetworkAuth { status in
            debugLog(" RealReachability - get local auth status = \(status)")
        }
    }

}

/// 在SwiftUI场景下的使用
@available(iOS 26.0, *)
struct RootMainView: View {
    @ObservedObject var reachability = RealReachability.shared
    
    @State var netstatus: String = "unknown"
    
    var body: some View {
        TabView {
            NavigationView {
                // ....
            }
        }
        .tabBarMinimizeBehavior(.onScrollUp)
        .tabViewBottomAccessory {
            if !reachability.isReachable {
                Text(verbatim: "当前网络连接异常，建议检查网络")
            }
        }
    }
}

