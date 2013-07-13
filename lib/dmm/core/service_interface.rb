module DMM
  module Core
    module ServiceInterface
      def self.included base 
        base.send(:attr_render, :config)
        base.send(:attr_render, :client)

        base.module_eval('module Errors; ned')
        
        unless base::Errors.include?(Errors)
          base::Errors.module_eval { include Errors }
        end
        DMM::Core::MetaUtils.extend(base) do
        
          def endpoint_prefix prefix = nil, options = {}
            if prefix
              @endpoint_prefix = prefix
              @global_endpoint = !!options[:global]
            end
            @endpoint_prefix
          end

          # @api private
          def global_endpoint?
            @global_endpoint
          end

          def regions
            RegionCollection.new(:service => self)
          end

        end

      end

      # Returns a new interface object for this service.  You can override
      # any of the global configuration parameters by passing them in as
      # hash options.  They are merged with AWS.config or merged
      # with the provided `:config` object.
      #
      #     @ec2 = AWS::EC2.new(:max_retries => 2)
      #
      # @see AWS::Cofiguration
      #
      # @param [Hash] options
      #
      # @option options [Configuration] :config An AWS::Configuration
      #   object to initialize this service interface object with.  Defaults
      #   to AWS.config when not provided.
      #
      def initialize options = {}
        options = options.dup
        @config = (options.delete(:config) || AWS.config)
        @config = @config.with(options)
        @client = @config.send(Inflection.ruby_name(self.class.name.split('::').last) + '_client')
      end

      # @return [String]
      def inspect
        "<#{self.class}>"
      end

    end
  end
end

