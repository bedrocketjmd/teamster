require 'sprockets'
require 'uglifier'
require 'pry'

require_relative 'builder'
require_relative 'sprockets'

module Deploy

  class Configs

    def initialize(&block)
      @settings = Config.new
      @settings.instance_eval(&block) if block_given?
      @deploy_dir = './.ng-deploy'
    end

    def package(config_name, &block)
      @settings.instance_eval(&block) if block_given?
      @settings
    end

    def build_files
      Builder.new(@settings, @sprockets, @deploy_dir).build_files
    end
  end

  class Config
    def initialize
      @groups = {}
      @settings = {}
    end

    def group(name, &block)
      group = (@groups[name] ||= Config.new)
      group.instance_eval(&block) if block_given?
      define_accessor(name) { group }
    end

    def set(key, value)
      define_accessor(key) { value }
      @settings[key] = value
    end

    private

    def define_accessor(name, &block)
      Deploy::Config.class_eval { define_method(name, &block) }
    end
  end

end
