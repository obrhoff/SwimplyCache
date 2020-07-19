Pod::Spec.new do |s|
  s.name = "SwimplyCache"
  s.version = "1.0.0"
  s.summary = "NSCache replacement written in Swift."
  s.homepage = "https://github.com/docterd/SwimplyCache"
  s.license = { :type => "MIT" }
  s.author = { "Dennis Oberhoff" => "dennis@obrhoff.de" }
  s.source = { :git => "https://github.com/docterd/swimplycache.git", :tag => "1.0.1"}
  s.source_files = "Sources/SwimplyCache/SwimplyCache.swift"
  s.osx.deployment_target  = '10.12'
  s.osx.framework  = 'Foundation'
  s.ios.deployment_target = "10.0"
  s.ios.framework = 'Foundation'
  s.tvos.deployment_target = "10.0"
  s.tvos.framework = 'Foundation'
  s.watchos.deployment_target = "3.0"
  s.watchos.framework = 'Foundation'
  s.swift_version = '5.0'
end
