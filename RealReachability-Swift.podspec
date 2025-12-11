#
#  Be sure to run `pod spec lint RealReachability.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#
Pod::Spec.new do |s|
  s.name         = "RealReachability-Swift"
  s.version      = "1.0.0"
  s.summary      = "We need to observe the REAL reachability of network for iOS. That's what RealReachability-Swift do too."


  # Add desc next time.
  s.homepage     = "https://github.com/Rex-xingjl/RealReachability-Swift"
  # Add screenshots next time.
  s.license      = "MIT"
  s.author             = { "Rex.Xing" => "343787863@qq.com" }
  s.platform = :ios
  s.ios.deployment_target = '13.0'
  s.source  = { :git => "https://github.com/Rex-xingjl/RealReachability-Swift", :tag => s.version, :submodules => true }
  s.source_files  = "RealReachability"
  s.swift_versions = '5.0'

end
