class Package
  attr_reader :package_config, :sprockets

  def initialize(package_config)
    @package_config = package_config
    @sprockets = Sprockets::Environment.new('./') { |env| }
    @package_config.asset_paths.each { |path| @sprockets.append_path( File.join( path ) ) }

    if @package_config.compress
      @sprockets.js_compressor = Uglifier.new(:mangle => false)
      @sprockets.css_compressor = YUI::CssCompressor.new
    end

    FileUtils.remove_dir(package_config.location, force: true)
    FileUtils.mkdir_p(package_config.location + '/assets')
    FileUtils.cp_r( Dir.glob('./public/*'), package_config.location )
    FileUtils.cp_r( './app', package_config.location )
    FileUtils.cp_r( Dir.glob('./assets/images/*'), "#{package_config.location}/assets" )
  end

  def pack
    compile_css
    compile_js
    build_dynamic_files
    build_index_html
  end

  def build_dynamic_files
    @package_config.dynamic_files.each do |file|
      File.open("#{package_config.location}/#{file.path}", 'w')  { |f| f.write(file.content) }
    end
  end

  def build_index_html
    data = ""
    f = File.open("#{package_config.location}/index.html", "r")
    f.each_line do |line|
      if line =~ /src=\"assets\/application.js/
        sprocket = sprockets['application.js']
        digest_paths = (package_config.concatenate) ? [sprocket.digest_path] : sprocket.dependencies.map(&:digest_path)
        data += digest_paths.
          collect { |js_file| "<script src=\"//#{package_config.host}/assets/#{js_file}\"></script>" }.
          join("\n")
      else
        data += line
      end
    end
    File.open("#{package_config.location}/index.html", 'w')  { |f| f.write data }
  end

  def compile_js
    printf "    => Compiling js assets ..."

    if package_config.concatenate
      ['application.js'].each do |file|
        asset = sprockets[file]
        outfile = Pathname.new("#{package_config.location}/assets").join(asset.digest_path)
        asset.write_to(outfile)
        asset.write_to("#{outfile}.gz")
      end
    else
      sprockets["application.js"].dependencies.each do |processed_asset|
        outfile = Pathname.new("#{package_config.location}/assets").join(processed_asset.digest_path)
        if package_config.compress
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
      outfile   = Pathname.new("#{package_config.location}/assets").join("#{file}.css")
      asset     = sprockets["#{file}.scss"]
      asset.write_to(outfile)
      asset.write_to("#{outfile}.gz")
    end

    puts " Done "
  end

  def deploy
    s3_config = package_config.target_service_configuration
    s3 = AWS::S3.new( access_key_id: s3_config.access_key_id,
                                              secret_access_key: s3_config.secret_access_key)
    bucket = s3.buckets[package_config.target_service_uri]

    print "Uploading site "

    Dir.glob("#{package_config.location}/**/*").each do |file|
      if File.file?(file)
        remote_file = file.gsub( "#{package_config.location}/", "" )
        print '.'
        s3_object = bucket.objects[remote_file]
        s3_object.write(file: file, content_type: MIME::Types.type_for(file).first)
      end
    end
    print "Done"
  end

end


# write_to method in Sprockets::Asset gem automatically compresses
# however I could not get it to work when using on asset dependencies. As a
# workaround added this method.
# TODO: figure out how to compress dependencies using sprocket gem itself

class Sprockets::Asset
  def modified_write_to filename, source, options = {}
    # Gzip contents if filename has '.gz'
    options[:compress] ||= File.extname(filename) == '.gz'

    FileUtils.mkdir_p File.dirname(filename)

    File.open("#{filename}+", 'wb') do |f|
      if options[:compress]
        # Run contents through `Zlib`
        gz = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
        # gz.mtime = mtime.to_i
        gz.write source
        gz.close
      else
        # Write out as is
        f.write source
      end
    end

    # Atomic write
    FileUtils.mv("#{filename}+", filename)

    # Set mtime correctly
    File.utime(mtime, mtime, filename)

    nil
  ensure
    # Ensure tmp file gets cleaned up
    FileUtils.rm("#{filename}+") if File.exist?("#{filename}+")
  end
end
