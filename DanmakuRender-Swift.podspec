#
# Be sure to run `pod lib lint DanmakuRender-Swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DanmakuRender-Swift'
  s.version          = '1.0'
  s.summary          = '一个跨 iOS/MacOS 平台的弹幕渲染器。'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
一个跨 iOS/MacOS 平台的弹幕渲染器，关注性能和拓展性。
                       DESC

  s.homepage         = 'https://github.com/jimhuang/DanmakuRender-Swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jimhuang' => 'sun_8434@163.com' }
  s.source           = { :git => 'https://github.com/jimhuang/DanmakuRender-Swift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.osx.deployment_target = "10.10"
  s.ios.deployment_target = "8.0"

  s.source_files = 'DanmakuRender-Swift/Classes/**/*'
  s.ios.framework  = 'UIKit'
  s.osx.framework  = 'AppKit'
  s.module_name = 'DanmakuRender'

  # s.resource_bundles = {
  #   'DanmakuRender-Swift' => ['DanmakuRender-Swift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'Cocoa'
  # s.dependency 'AFNetworking', '~> 2.3'
end
