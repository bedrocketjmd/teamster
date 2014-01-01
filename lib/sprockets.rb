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
