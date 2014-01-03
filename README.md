Sample config:

```ruby
desc 'deploy to s3'
namespace :deploy do

  task :acceptance do

    package = Teamster::Configuration::Package.new do

      # package_dir                 "tmp/teamster"

	  # directories sprockets will look into
      javascripts do
        directory                 'vendor'
        directory                 'app'
        directory                 'config'
      end

      stylesheets do
        directory                 'assets/stylesheets'
      end

	  # files from the project that need to be copied over
      copy_files                  ['public/*', 'app', { src: 'assets/images/*', dest: 'assets' }]

	  # combine css/js files into one
      concatenate                 true

	  # compress css/js files
      compress                    true

	  # s3 config
      deploy_to                   "desktop-acceptance.networka.com" do
        access_key_id             ENV['AWS_ACCESS_KEY_ID']
        secret_access_key         ENV['AWS_SECRET_ACCESS_KEY']
      end

	  # cdn url
      host                        '//dmr7xap4dxyc8.cloudfront.net'

	  # environment.json file
      file 'environment.json', format: :json do | json |
        json.api do
          json.uri                'http://api-acceptance.bedrocketplatform.com'
          json.property_code      'networka'
        end
        json.cdn  do
          json.uri                'http://cdn-acceptance.bedrocketplatform.com'
        end
        json.google_analytics do
          json.id  'UA-40421422-4'
        end
      end

    end

    package.pack
    package.deploy unless ENV['skip_upload']

  end

end
```
