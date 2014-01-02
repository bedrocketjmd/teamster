angular-deploy
==============

A gem to deploy angularjs applications to a S3 ( and perhaps in the future other locations ).


Sample config

```ruby

require 'angular_deploy'

desc 'deploy to s3'
namespace :deploy do

  task :acceptance do

    deploy = AngularDeploy::Configs.new do
      set :deploy_to,                'dmr7xap4dxyc8.cloudfront.net'
      set :bucket,                   'desktop-acceptance.networka.com'
      set :concatenate,              true
      set :compress,                 true
      set :s3_access_key_id,          ENV['AWS_ACCESS_KEY_ID']
      set :s3_secret_access_key,      ENV['AWS_SECRET_ACCESS_KEY']

      group :environment do
        group :api do
          set :uri,                 'http://api-acceptance.bedrocketplatform.com'
        end
        set :cdn,                    'http://cdn-acceptance.bedrocketplatform.com'
        set :property_code,         'networka'
        set :google_analytics_id,   'UA-40421422-4'
      end

      set :sprockets_path, [ 'vendor', ['assets', 'images'], ['assets', 'stylesheets'], 'app', 'config' ]
    end

    deploy.build_files
    deploy.upload_to_s3 unless ENV['skip_upload']

  end

end

```

