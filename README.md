<img width="300" height="300" alt="icon-image" src="https://github.com/user-attachments/assets/23aa462c-efee-4e40-b394-042d48f5ec7d" />

[English](README.en.md) | [简体中文](README.md)

# RealReachability-Swift
没错，就是你想的那个。判断**实时网络真实连通性**的控件，不仅仅显示处于什么网络环境。

# 前言
灵感来自于 https://github.com/dustturtle/RealReachability
该项目使用 ping 来实时探测网络连接情况，可以避免处于某种网络但是实际无通信能力的情况

在实际使用中，我们遇到了一些复杂的网络场景，** ping 不通但是 http 请求正常**，例如：虚拟 ip 访问。
这给我们带来的一些意料外的情况。

所以在进行 Swift 改造时，我将 Ping 连接改为了使用 URLSession 进行轻量的 Head 请求，
这样，可以做到大部分情况下的连通性判断都是准确的。

# 实现

使用先进的原生框架 Combine + async/await 来进行实现，来减少对项目的额外负担。
内部状态变化的接收在异步线程中执行，并统一在主线程中进行发布，以避免使用时意外的在子线程修改界面。

# 应用支持

**系统版本** `iOS14+`

**界面框架** `UIKit` / `SwiftUI`

# 使用方式

你需要做的前置步骤，只有这个：

```swift

/// 设置检测的域名地址 一般从数据中拿到的都是字符串 所以这里不要求传URL

RealReachability.shared.setHTTPCheck(urls: ["https://www.apple.com"],
                                     timeout: 2,
                                     interval: 5)

```

后续可以任意使用：

```swift

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

```

# 持续维护

如果遇到问题，请 Issues 我，我将尽快提供支持（在工作之余）。

`Rex.Xing @2025.12.11`

