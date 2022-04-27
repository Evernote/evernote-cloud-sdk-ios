Pod::Spec.new do |spec|
  spec.name = "evernote-cloud-sdk-ios"
  spec.version = "2.0.6"
  spec.summary = "Evernote Cloud SDK for iOS."
  spec.homepage = "https://github.com/evernote/evernote-cloud-sdk-ios"
  spec.license = '  https://github.com/evernote/evernote-cloud-sdk-ios/blob/master/LICENSE'
  spec.authors = { 'Evernote' => 'devsupport@evernote.com' }
  spec.source = { :git => "https://github.com/evernote/evernote-cloud-sdk-ios.git", :tag => "2.0.6"}
  spec.ios.deployment_target = "8.0"
  spec.xcconfig = {'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2 ${PODS_ROOT}/Headers/Public/evernote-cloud-sdk-ios/SendToEvernoteActivity'}

  spec.source_files = "evernote-sdk-ios/**/*.{h,m}",
  spec.exclude_files = "evernote-sdk-ios/evernote-sdk-ios-Prefix.pch",
  spec.resource = "ENSDKResources.bundle"
  spec.requires_arc = true

  spec.framework = "CoreServices", "CoreGraphics", "Foundation", "UIKit"
  spec.library = "xml2"
  
  spec.deprecated_in_favor_of = "EvernoteSDK"
end
