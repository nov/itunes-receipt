# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'itunes-receipt'
  s.description = %q{Handle iTunes In App Purchase Receipt Verification}
  s.summary     = %q{Handle iTunes In App Purchase Receipt Verification}
  s.version     = File.read(File.join(File.dirname(__FILE__), 'VERSION'))
  s.authors     = ['nov matake']
  s.email       = 'nov@matake.jp'
  s.homepage    = 'http://github.com/nov/itunes-receipt'
  s.require_paths = ['lib']
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency 'json', '>= 1.4.3'
  s.add_dependency 'rest-client'
  s.add_dependency 'activesupport', '>= 2.3'
  s.add_dependency 'i18n'
  s.add_development_dependency 'rake', '>= 0.8'
  s.add_development_dependency 'rspec', '>= 2'
  s.add_development_dependency 'fakeweb', '>= 1.3.0'
  s.add_development_dependency 'simplecov'
end
