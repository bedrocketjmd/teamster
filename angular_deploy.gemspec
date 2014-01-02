Gem::Specification.new do |s|
  s.name        = 'angular-deploy'
  s.version     = '0.0.1'
  s.date        = '2013-12-25'
  s.description = "Gem to build and deploy angular spa application"
  s.summary     = "Builds and deploys necessary html and js/css files based on sprockets configuration."
  s.authors     = ["Shovan Joshi"]
  s.email       = 'shovanj@gmail.com'
  s.files       = ["lib/angular_deploy.rb"]
  s.homepage    = ""
  s.license       = 'MIT'

  s.add_dependency "sprockets", "~> 2.10.1"

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "aws-sdk", "1.30.0"
  s.add_development_dependency "pry"
end
