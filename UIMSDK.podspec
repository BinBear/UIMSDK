Pod::Spec.new do |s|
  s.name         = "UIMSDK"
  s.version      = "1.9.5"
  s.summary      = "SignalR framework create by devpro."
  s.homepage     = "https://github.com/retsohuang/UIMSDK"
  s.license      = "Apache License 2.0"
  s.author       = { "Retso Huang" => "retsohuang@gmail.com" }
  s.platform     = :ios
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/retsohuang/UIMSDK.git", :tag => s.version.to_s }
  s.source_files = "Source", "Source/Public/*.h"
  s.public_header_files = "Source/Public/*.h"
  s.requires_arc = true
  s.dependency "SignalR-ObjC", "2.0.0.alpha1"
  s.dependency "ReactiveCocoa"
end
