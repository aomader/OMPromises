Pod::Spec.new do |s|
  s.name         = 'OMPromises'
  s.version      = '0.8.0'
  s.summary      = 'Promises for iOS & Mac OS X'
  s.homepage     = 'http://github.com/b52/OMPromises'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Oliver Mader' => 'b52@reaktor42.de' }
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.tvos.deployment_target = '9.0'
  s.source       = { :git => 'https://github.com/b52/OMPromises.git', :tag => s.version.to_s }
  s.requires_arc = true

  s.default_subspec = 'Core'

  s.subspec 'Core' do |cs|
    cs.source_files = 'Sources/OMPromises.h', 'Sources/Core', 'Sources/Core/External'
    cs.public_header_files = 'Sources/OMPromises.h', 'Sources/Core/{OMPromises,OMPromise,OMDeferred,OMLazyPromise}.h'
  end

  s.subspec 'HTTP' do |hs|
    hs.dependency 'OMPromises/Core'
    hs.source_files = 'Sources/OMHTTP.h', 'Sources/HTTP'
    hs.public_header_files = 'Sources/OMHTTP.h', 'Sources/HTTP/*.h'
    hs.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'OMPROMISES_HTTP_AVAILABLE=1' }
  end

  s.subspec 'Tests' do |ts|
    ts.dependency 'OMPromises/Core'
    ts.dependency 'OMPromises/HTTP'
    ts.framework = 'XCTest'
    ts.source_files = 'Tests/*.{h,m}', 'Tests/{Core,HTTP}/*.{h,m}'
    ts.prefix_header_contents = <<-EOS
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif
EOS
  end
end
