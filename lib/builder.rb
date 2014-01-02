module AngularDeploy
  class Builder

    attr_reader :settings, :sprockets

    def initialize(settings, sprockets, deploy_dir)
      @settings, @sprockets, @deploy_dir = settings, sprockets, deploy_dir
      @sprockets = Sprockets::Environment.new('./') { |env| }
      @settings.sprockets_path.each { |path| @sprockets.append_path( File.join( path ) ) }
      @sprockets.js_compressor = Uglifier.new(:mangle => false) if @settings.compress

      FileUtils.remove_dir(@deploy_dir, force: true)
      FileUtils.mkdir_p(@deploy_dir + '/assets')
      FileUtils.cp_r( Dir.glob('./public/*'), @deploy_dir )
      FileUtils.cp_r( './app', @deploy_dir )
      FileUtils.cp_r( Dir.glob('./assets/images/*'), "#{@deploy_dir}/assets" )
    end

    def build_files
      compile_css
      compile_js
      build_environemt_file
      build_index_html
    end

    def build_environemt_file
      env_config = {
        api: {
          uri: settings.environment.api.uri,
          property_code: settings.environment.property_code
        },
        cdn: {
          uri: settings.environment.cdn
        },
        google_analytics: {
          id: settings.environment.google_analytics_id
        }
      }
      File.open("#{@deploy_dir}/environment", 'w')  { |f| f.write env_config.to_json }
    end

    def build_index_html
      data = ""
      f = File.open("#{@deploy_dir}/index.html", "r")
      f.each_line do |line|
        if line =~ /src=\"assets\/application.js/
          sprocket = sprockets['application.js']
          digest_paths = (settings.concatenate) ? [sprocket.digest_path] : sprocket.dependencies.map(&:digest_path)
          data += digest_paths.
            collect { |js_file| "<script src=\"//#{settings.deploy_to}/assets/#{js_file}\"></script>" }.
            join("\n")
        else
          data += line
        end
      end
      File.open("#{@deploy_dir}/index.html", 'w')  { |f| f.write data }
    end

    def compile_js
      printf "    => Compiling js assets ..."

      if settings.concatenate
        ['application.js'].each do |file|
          asset = sprockets[file]
          outfile = Pathname.new("#{@deploy_dir}/assets").join(asset.digest_path)
          asset.write_to(outfile)
          asset.write_to("#{outfile}.gz")
        end
      else
        sprockets["application.js"].dependencies.each do |processed_asset|
          outfile = Pathname.new("#{@deploy_dir}/assets").join(processed_asset.digest_path)
          if settings.compress
            puts "Compressing js asset #{processed_asset.digest_path}."
            processed_asset.modified_write_to(outfile, Uglifier.compile(processed_asset.source, :mangle => false))
            processed_asset.modified_write_to("#{outfile}.gz", Uglifier.compile(processed_asset.source, :mangle => false))
          else
            processed_asset.write_to(outfile)
            processed_asset.write_to("#{outfile}.gz")
          end
        end
      end
      puts " Done"
    end

    def compile_css
      printf "    => Compiling css assets ..."

      ['application'].each do |file|
        outfile   = Pathname.new("#{@deploy_dir}/assets").join("#{file}.css")
        asset     = sprockets["#{file}.scss"]
        asset.write_to(outfile)
        asset.write_to("#{outfile}.gz")
      end

      puts " Done "
    end

    def upload_to_s3
      s3 = AWS::S3.new( access_key_id: @settings.s3_access_key_id,
                        secret_access_key: @settings.s3_secret_access_key)
      bucket = s3.buckets[@settings.bucket]
      print "Uploading site "

      Dir.glob("#{@deploy_dir}/**/*").each do |file|
        if File.file?(file)
          remote_file = file.gsub( @deploy_dir, "" )
          print '.'
          s3_object = bucket.objects[remote_file]
          s3_object.write(file: file, content_type: MIME::Types.type_for(file).first)
        end
      end
      print "Done"
    end
  end

end
