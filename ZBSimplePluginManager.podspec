Pod::Spec.new do |s|
  s.name             = 'ZBSimplePluginManager'
  s.version          = '0.0.1'
  s.summary          = 'A simple plug-in system by using JavaScriptCore.'
  s.description      = <<-DESC
  Apple introduced JavaScriptCore framework, a JavaScript interpreter, in iOS 7. 
  It is a great tool and we leverage it to build a simple plug-in system to extend 
  flexibility of your app easily.
                       DESC

  s.homepage         = 'https://github.com/zonble/ZBSimplePluginManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zonble' => 'zonble@gmail.com' }
  s.source           = { :git => 'https://github.com/zonble/ZBSimplePluginManager.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/zonble'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.source_files = 'Sources/ZBSimplePluginManager/**/*'
end
