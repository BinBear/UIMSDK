Pod::Spec.new do |s|
  s.name         = "UIMSDK"
  s.version      = "0.0.1"
  s.summary      = "SignalR framework create by devpro."
  s.homepage     = "https://github.com/retsohuang/UIMSDK"
  s.license      = "Apache License 2.0"
  s.author             = { "Retso Huang" => "retsohuang@gmail.com" }
  s.platform     = :ios
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/retsohuang/UIMSDK.git", :tag => s.version.to_s }
  s.source_files  = "Source/*.{h,m}"
  s.public_header_files = "Source/Public/"
  s.requires_arc = true
  s.dependency "SignalR-ObjC"
  s.dependency "ReactiveCocoa"
end
