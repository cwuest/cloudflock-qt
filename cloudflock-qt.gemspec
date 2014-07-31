$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'cloudflock-qt'

Gem::Specification.new do |s|
  s.name = 'cloudflock-qt'
  s.version = CloudFlockQt::VERSION

  s.description = 'Graphical frontend for CloudFlock in Qt'
  s.summary     = 'Unix migration automation'
  s.authors     = ['Chris Wuest']
  s.email       = 'chris@chriswuest.com'
  s.homepage    = 'http://github.com/cwuest/cloudflock-qt'

  s.add_runtime_dependency('cloudflock', '~>0.7', '>=0.7.2')
  s.add_runtime_dependency('qtbindings', '~> 4.8')

  s.files = `git ls-files lib`.split("\n")
  s.files += `git ls-files bin`.split("\n")
  s.files.reject! { |f| f.include?('.dev') }

  s.executables = `git ls-files bin`.split("\n")
  s.executables.map!    { |f| f.gsub!(/^bin\//, '') }
  s.executables.reject! { |f| f.include?('.dev') }

  s.license = 'Apache 2.0'
end
