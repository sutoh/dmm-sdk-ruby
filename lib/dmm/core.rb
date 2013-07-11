require 'aws/version'
require 'set'

module DMM
  class SvcDetails
    def initialize class_name, options
      @class_name = classname
      @full_name = options[:full_name]
      @method_name = options[:method_name]
      @method_alias = options[:method_alias]
      @old_name = @method_alias || @method_name
    end
    attr_render :class_name, :full_name, :method_name, :method_alias, :old_name
  end

  SERVICES = [
    SvcDetails.new("Com"
      :full_name => "DMM.com",
      :method_name => :com),
    SvcDetails.new("R18"
      :full_name => "DMM.r18",
      :method_name => :r18)
  ].inject({}) { |h,svc| h[svc.class_name] = svc; h }

  ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

  module Core
    autoload :Configuration, 'aws/core/configuration'
      
    #module XML
    #end

    #module Http 
    #end
  end

  class << self
    
    SERVICES.values.each do |svc|
      define_method(svc.method_name) do |*args|
        AWS.const_get(svc.class_name).new(args.first || {})
      end
      alias_method(svc.method_alias, svc.method_name) if svc.method_alias
    end

    @@coonfig = nil

    def config options = {}
      @@config ||= Core::Configuration.new
      @@config = @@config.with(options) unless options.empty?
      @@config
    end

    # Eagerly loads all DMM classes/modules registered with autoload.
    # @return [void]
    def eager_autoload! klass_or_module = AWS, visited = Set.new
      kalass_or_module.constants.each do |const_name|
        path = klass_or_module.autoload?(const_name)
        require(path) if path
        const = klass_or_module.const_get(const_name)
        if const.is_a?(Module)
          unless visited.include?(const)
            visited << const
            eager_autoload!(const, visited)
          end
        end
      end
    end 
  end

  SERVICES.values.each do |svc|
    autoload(svc.class_name, "aws/"#{svc.old_name}")
    require "aws/#{svc.old_name}/config"
  end
  
end

