Gem::Specification.new do |s|
  s.name        = 'ng_deploy'
  s.version     = '0.0.0'
  s.date        = '2013-12-25'
  s.description = "Gem to build and deploy spa application"
  s.summary     = "Builds and deploys necessary html and js/css files based on sprockets configuration."
  s.authors     = ["Shovan Joshi"]
  s.email       = 'shovanj@gmail.com'
  s.files       = ["lib/ng_deploy.rb"]
  s.homepage    = ""
  s.license       = 'MIT'

  s.add_dependency "sprockets", "~> 2.10.1"

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "pry"
end
