Pod::Spec.new do |spec|
  spec.name = "evernote-cloud-sdk-ios"
  spec.version = "2.0.1"
  spec.summary = "Evernote Cloud SDK for iOS."
  spec.homepage = "https://github.com/evernote/evernote-cloud-sdk-ios"
  spec.license = '  https://github.com/evernote/evernote-cloud-sdk-ios/blob/master/LICENSE'
  spec.authors = { 'Evernote' => 'devsupport@evernote.com' }
  spec.source = { :git => "https://github.com/evernote/evernote-cloud-sdk-ios.git", :tag => "2.0.1"}
  spec.ios.deployment_target = "7.0"
  spec.xcconfig = {'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2'}

  spec.public_header_files = "evernote-sdk-ios/ENSDK/SendToEvernoteActivity/ENSaveToEvernoteActivity.h",
  spec.header_mappings_dir = "evernote-sdk-ios/",
  spec.source_files = "evernote-sdk-ios/**/*.{h,m}",
  spec.exclude_files = "evernote-sdk-ios/evernote-sdk-ios-Prefix.pch",
  spec.resource = "ENSDKResources.bundle"
  spec.requires_arc = true

  spec.framework = "libxml2", "MobileCoreServices", "CoreGraphics", "Foundation", "UIKit"
  spec.library = "xml2"
end
