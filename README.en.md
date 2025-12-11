# RealReachability-Swift

Yes, it is exactly what you think it is. This component determines the **actual, real-time network reachability**, not just the current network environment shown by the system.

## Introduction

The inspiration comes from https://github.com/dustturtle/RealReachability.  
That project uses **ping** to detect network connectivity in real time, which helps avoid situations where the device appears to be connected to a network but has no real communication capability.

In real-world usage, we encountered several complex network scenarios where **ping fails but HTTP requests succeed**, such as virtual IP access. These cases produced some unexpected behaviors.

Therefore, during the Swift rewrite, I **replaced the Ping mechanism with lightweight HEAD requests via URLSession**, ensuring that network reachability detection is accurate in most situations.

## Implementation

This library is implemented using modern native frameworks: **Combine + async/await**, minimizing additional burden on your project.  
All internal state updates are processed on background threads, then published uniformly on the main thread to avoid unexpected UI updates from background threads.

## Platform Support

- iOS 14+
- UIKit / SwiftUI

## Usage

The only required setup step:

```swift

/// Configure the domains to check. These are usually strings retrieved from your data source,
/// so you do not need to pass URL types here.
RealReachability.shared.setHTTPCheck(urls: ["https://www.apple.com"],
                                     timeout: 2,
                                     interval: 5)
After that, you can use the following:

```swift

/// 🛜 Real-time network status
/// 1. If reachable, returns the current network type: wifi, cellular, etc.
/// 2. Otherwise, returns unreachable.
RealReachability.shared.$status
    .dropFirst()
    .receive(on: DispatchQueue.main)
    .sink { debugLog(" RealReachability - internet status = \($0)") }
    .store(in: &cancelBag)

/// 🟢 Local network permission
RealReachability.shared.$permission
    .dropFirst()
    .receive(on: DispatchQueue.main)
    .sink { debugLog(" RealReachability - internet permission = \($0)") }
    .store(in: &cancelBag)

/// 📶 Cellular network details
RealReachability.shared.$cellularType
    .dropFirst()
    .receive(on: DispatchQueue.main)
    .sink { debugLog(" RealReachability - internet cellularType = \($0)") }
    .store(in: &cancelBag)

/// ✅ Check only external internet reachability
RealReachability.shared.$isReachable
    .dropFirst()
    .receive(on: DispatchQueue.main)
    .sink { debugLog(" RealReachability - internet isReachable = \($0)") }
    .store(in: &cancelBag)

/// Actively fetch the next detection result
RealReachability.shared.getInternetStatus {
    debugLog(" RealReachability - get internet status = \($0)")
}

/// Retrieve local network permission
RealReachability.shared.getLocalNetworkAuth { status in
    debugLog(" RealReachability - get local auth status = \(status)")
}

```
# Continuous Maintenance

If you encounter any issues, please submit an Issue. I will provide support as soon as possible (in my spare time).

Rex Xing
2025.12.11
