Gem::Specification.new do |s|
  s.name        = 'teamster'
  s.version     = '0.0.8'
  s.date        = '2013-12-25'
  s.description = "Gem to build and deploy js spa application"
  s.summary     = "Builds and deploys necessary html and js/css files based on sprockets configuration."
  s.authors     = ["Bedrocket"]
  s.email       = 'product-team@bedrocket.com'
  s.files       = ["lib/teamster.rb"]
  s.homepage    = ""
  s.license       = 'MIT'

  s.add_dependency "sprockets", "2.12.0"
  s.add_dependency "sprockets-sass", "1.0.3"
  s.add_dependency "uglifier", "2.3.2"
  s.add_dependency "bundler", "~> 1.3"
  s.add_dependency "aws-sdk", "1.38.0"
  s.add_dependency "mime-types", "1.23"
  s.add_dependency "cssminify", "1.0.2"
  s.add_dependency "jbuilder", "2.0.2"

  s.add_development_dependency "pry"
end
