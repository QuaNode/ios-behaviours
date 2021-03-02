#
#  Be sure to run `pod spec lint ios-behaviours.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "Behaviours"
  spec.version      = "2.0.9"
  spec.summary      = "iOS and macOS client for Behaviours"
  spec.description  = "Behavious is a BaaS platform built on BeamJS"
  spec.homepage     = "http://quanode.com"
  spec.license      = { :type => 'MIT' }
  spec.author       = { "QuaNode" => "info@quanode.com" }
  spec.platform     = :ios
  spec.platform     = :osx
  spec.ios.deployment_target = "8.0"
  spec.osx.deployment_target = "10.10"
  spec.source       = { :git => "https://github.com/QuaNode/ios-behaviours.git", :tag => "v2.0.9" }
  spec.source_files = "Behaviours-SDK-iOS"

end
