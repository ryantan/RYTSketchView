#
# Be sure to run `pod lib lint RYTSketchView.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "RYTSketchView"
  s.version          = "0.1.0"
  s.summary          = "A short description of RYTSketchView."
  s.description      = <<-DESC
                       Allow users to draw in your app, with brush size and color options, undo and redo with history, zooming, erasing, area cut and pasting.
                       DESC
  s.homepage         = "https://github.com/ryantan/RYTSketchView"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Ryan" => "ryan@redairship.com" }
  s.source           = { :git => "https://github.com/ryantan/RYTSketchView.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/squall3d'

  s.platform     = :ios, '6.1'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'RYTSketchView' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.ios.dependency 'MBProgressHUD', '~> 0.5'
  # s.ios.dependency 'HexColors'
  s.ios.dependency 'UIColor+Hex'
end
