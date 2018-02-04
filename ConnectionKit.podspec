Pod::Spec.new do |s|
 s.name = 'ConnectionKit'
 s.version = '0.0.1'
 s.license = { :type => "MIT", :file => "LICENSE" }
 s.summary = 'ConnectionKit'
 s.homepage = 'http://ddrccw.github.io/'
 s.authors = { "ddrccw" => "ddrccw@gmail.com" }
 s.source = { :git => "https://github.com/ddrccw/ConnectionKit.git", :tag => "v"+s.version.to_s }
 s.platforms = { :ios => "8.0" }
 s.requires_arc = true

 s.default_subspec = "Core"
 s.subspec "Core" do |ss|
     ss.source_files  = "ConnectionKit/Classes/**/*.swift"
     ss.framework  = "Foundation"
 end

end
