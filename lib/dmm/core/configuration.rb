require 'set'
require 'uri'

module AWS
  module Core
    class Confiduration

      # Creates a new Configuration object.
      # @param options (see DMM.config)
      # @option options (see DMM.config)
      def initialize options = {}
        @created = options.delete(:__created__) || {}

        options.each_pair do |opt_name, value|
          opt_name = opt_name.to_sym
          if self.class.accepted_options.include?(opt_name)
            supplied[opt_name] = value
          end
        end
      end
      
      # @return [Hash] Returns a hash with your configured credentials.
      def credentials
        credentials = {}
        [:api_id, :affiliate_id].each do |opt|
          if value = credential_provider.send(opt)
            credentials[opt] = value
          end
        end
        credentials
      end
      
      
      def with options = {}
        # symbolize option keys
        options = options.inject({}) {|h,kv| h[kv.first.to_sym] = kv.last; h }
        values = supplied.merge(options)
        if supplied == values
          self # nothing changed
        else
          self.class.new(values.merge(:__created__ => @created.dup))
        end
      end


      # @return [Hash] Returns a hash of all configuration values.
      def to_h
        self.class.accepted_options.inject({}) do |h,k|
          h.merge(k => send(k))
        end
      end
      alias_method :to_hash, :to_h
      

      # @return [Boolean] Returns true if the two configuration objects have
      #   the same values.
      def eql? other
        other.is_a?(self.class) and self.supplied == other.supplied
      end
      alias_method :==, :eql?

    
      def inspect
        "<#{self.class.name}>"
      end
      

      protected
      
      add_options :api_id
      
      add_options :affiliate_id

      def supplied
        @supplied ||= {}
      end

      =begin
      class << self
        def accepted_options
          @options ||= Set.new
        end


        def add_option name, default_value = nil, options = {}, &transform
          accepted_options << name
          define_method(name) do |&default_override|
            value =
              if supplied.has_key?(name)
                supplied[name]
              elsif default_override
                default_override.call
              else
                default_value
              end
            transform ? transform.call(self, value) : value
          end
          alias_method("#{name}?", name) if options[:boolean]
        end
        

        # Configuration options that have dependencies are re-recreated
        # anytime one of their dependent configuration values are
        # changed.
        # @api private
        def add_option_with_needs name, needs, &create_block
          accepted_options << name
          define_method(name) do
            return supplied[name] if supplied.has_key?(name)
            needed = needs.inject({}) {|h,need| h.merge(need => send(need)) }
            unless @created.key?(name) and @created[name][:needed] == needed
              created = {}
              created[:object] = create_block.call(self,needed)
              created[:needed] = needed
              @created[name] = created
            end
            @created[name][:object]
          end
        end

        def add_service name, ruby_name, endpoint_pattern = nil, &endpoint_builder
          svc = SERVICES[name]
          svc_opt = svc.method_name
          ruby_name = svc.old_name
          add_option(svc_opt, {})
          needs = [
            :"#{ruby_name}_endpoint",
            :"#{ruby_name}_port",
            :"#{ruby_name}_region",
            :credential_provider,
            :http_handler,
            :http_read_timeout,
            :http_continue_timeout,
            :http_continue_threshold,
            :log_formatter,
            :log_level,
            :logger,
            :proxy_uri,
            :max_retries,
            :stub_requests?,
            :ssl_verify_peer?,
            :ssl_ca_file,
            :ssl_ca_path,
            :use_ssl?,
            :user_agent_prefix,
          ]
          create_block = lambda do |config,client_options|
            AWS.const_get(name)::Client.new(:config => config)
          end
          add_option_with_needs :"#{ruby_name}_client", needs, &create_block
        end
      end
      =end   
    end
  end
end
