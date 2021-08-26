#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mic_stream.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mic_stream'
  s.version          = '0.5.2'
  s.summary          = 'Provides a tool to get the microphone input as PCM Stream'
  s.description      = <<-DESC
  Provides a tool to get the microphone input as PCM Stream
                       DESC
  s.homepage         = 'https://github.com/anarchuser'
  s.license          = { :file => '../LICENSE' }
  s.author           = { '' => '' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
