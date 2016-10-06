Pod::Spec.new do |s|
s.name             = 'ZigzagKit'
s.version          = '0.1.41'
s.summary          = 'UIKit helpers & components for iOS'

s.description      = <<-DESC
UIKit helpers & components for iOS
DESC

s.homepage         = 'https://github.com/Zigzag968/ZigzagKit'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'Alexandre Guibert' => 'alexandre968@hotmail.com' }
s.source           = { :git => 'https://github.com/Zigzag968/ZigzagKit.git', :tag => 'v0.1.41' }

s.ios.deployment_target = '8.0'

s.source_files = 'ZigzagKit/Classes/**/*'

end