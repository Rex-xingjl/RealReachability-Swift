//
//  InternetHTTPChecker.swift
//  
//
//  Created by Rex Xing on 2025/12/10.
//

import Foundation
import Combine

/// HTTP网络连通检测 ``请注意这是个actor 确保内部数据线程安全``
final actor InternetHTTPChecker {
    typealias CallBack = (Bool) -> Void
    
    private var urls: [URL] = []
    private var interval: TimeInterval = 5.0
    private var timeout: TimeInterval = 2.0
    
    private var loopTask: Task<Void, Never>?
    private var callbacks: [CallBack] = []
    private var checking: Bool = false

    private lazy var session = {
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.httpCookieStorage = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: config)
        return session
    }()
    
    /// 真实连接状态
    @Published private(set) var isReachable: Bool = true
    
    /// 设置检测的域名
    ///
    /// - Parameter urls: 域名URL地址数组
    /// - Parameter timeout: 请求超时时间
    /// - Parameter interval: 请求轮次间隔时间  ``checking 从true=>false为一轮 ``
    func setCheck(urls: [String], timeout: TimeInterval = 2.0, interval: TimeInterval = 5.0) async {
        stopCheck()
        
        self.urls = urls.compactMap {
            $0.hasPrefix("https://") ? URL(string: $0) : URL(string: "https://" + $0)
        }
        self.timeout = timeout
        self.interval = interval
        
        loopTask = Task {
            while !Task.isCancelled {
                await startCheck()
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    /// 发起一个请求轮次
    /// 任何主动调起且传入 completion 的事件，都会在轮次结束时统一收到回调
    /// 当次周期未完成时，不会进行下一次轮次
    ///
    /// - Parameter completion: 回调事件
    func startCheck(_ completion: CallBack? = nil) async {
        if let completion { callbacks.append(completion) }
        
        guard !checking else { return }
        checking = true
            
        let callCache = callbacks
        callbacks = []
        var reachable = false
        for url in urls {
            guard await headRequest(url) else { continue }
            reachable = true
            break
        }
        isReachable = reachable
        callCache.forEach { $0(reachable) }
        checking = false
    }
    
    /// 结束当前请求轮次
    func stopCheck() {
        loopTask?.cancel()
        callbacks.removeAll()
        urls.removeAll()
        checking = false
    }

    /// 发起尽可能做到轻量的 Head 请求
    ///
    /// - Parameter url: 目标地址
    private func headRequest(_ url: URL) async -> Bool {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout
        request.setValue(nil, forHTTPHeaderField: "Cookie")
        request.setValue("RealReachability/1.0", forHTTPHeaderField: "User-Agent")

        let success = await withCheckedContinuation { continuation in
            let task = session.dataTask(with: request) { _, response, _ in
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse?.statusCode ?? -1
                let success = statusCode >= 200 && statusCode < 400
                continuation.resume(returning: success)
            }
            task.resume()
        }
        return success
    }
    
}
