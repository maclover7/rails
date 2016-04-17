module ActionDispatch
  module Routing
    class RouteBuilder
      ANCHOR_CHARACTERS_REGEX = %r{\A(\\A|\^)|(\\Z|\\z|\$)\Z}
      JOINED_SEPARATORS = SEPARATORS.join

      attr_reader :ast

      def initialize(mapping, route_set)
        @mapping = mapping
        @route_set = route_set
        @routes = @route_set.routes
        @scope = @mapping.instance_variable_get(:@scope)
      end

      def call(action, controller, options, path, to, via, formatted, anchor, options_constraints)
        ## Format path
        @path = format_path(action, path, formatted)

        action = action.to_s
        default_action = options.delete(:action) || @scope[:action]

        if action =~ /^[\w\-\/]+$/
          default_action ||= action.tr('-', '_') unless action.include?("/")
        else
          action = nil
        end

        @as = if !options.fetch(:as, true) # if it's set to nil or false
                options.delete(:as)
              else
                name_for_action(options.delete(:as), action)
              end

        options = @scope[:options].merge(options) if @scope[:options]
        defaults = (@scope[:defaults] || {}).dup
        scope_constraints = @scope[:constraints] || {}

        modyoule = @scope[:module]
        blocks = @scope[:blocks] || []

        @ast = Journey::Parser.parse(@path)

        ###

          @defaults = defaults
          #@set = set

          @to                 = to
          @default_controller = controller
          @default_action     = default_action
          @ast                = ast
          @anchor             = anchor
          @via                = via
          @internal           = options[:internal]

          path_params = ast.find_all(&:symbol?).map(&:to_sym)

          ## Format options
          options = format_options(options, formatted, path_params, ast, modyoule)
          #require 'pry'; binding.pry

          split_options = constraints(options, path_params)

          constraints = scope_constraints.merge Hash[split_options[:constraints] || []]

          if options_constraints.is_a?(Hash)
            @defaults = Hash[options_constraints.find_all { |key, default|
              Routing::Mapper::URL_OPTIONS.include?(key) && (String === default || Fixnum === default)
            }].merge @defaults
            @blocks = blocks
            constraints.merge! options_constraints
          else
            @blocks = blocks(options_constraints)
          end

          requirements, conditions = split_constraints path_params, constraints
          verify_regexp_requirements requirements.map(&:last).grep(Regexp)

          formats = normalize_format(formatted)

          @requirements = formats[:requirements].merge Hash[requirements]
          @conditions = Hash[conditions]
          @defaults = formats[:defaults].merge(@defaults).merge(normalize_defaults(options))

          @required_defaults = (split_options[:required_defaults] || []).map(&:first)

        add_route
      end
      #####

      private

      def action_path(name) #:nodoc:
        @scope[:path_names][name.to_sym] || name
      end

      def add_controller_module(controller, modyoule)
        return controller unless modyoule && !controller.is_a?(Regexp)

        if controller =~ %r{\A/}
          controller[1..-1]
        else
          [modyoule, controller].compact.join("/")
        end
      end

      def add_route
        route = Journey::Route.new(@as,
                                    application,
                                    compiled_path,
                                    @conditions,
                                    @required_defaults,
                                    @defaults,
                                    request_method,
                                    @routes.length,
                                    @internal)
        @route_set.add_route(@as, route)
      end

      def application
        if @to.is_a?(Class) && @to < ActionController::Metal
          Routing::RouteSet::StaticDispatcher.new @to
        else
          if @to.respond_to?(:call)
            Routing::Mapper::Constraints.new(@to, @blocks, Routing::Mapper::Constraints::CALL)
          elsif @blocks.any?
            Routing::Mapper::Constraints.new(dispatcher(@defaults.key?(:controller)), @blocks, Routing::Mapper::Constraints::SERVE)
          else
            dispatcher(@defaults.key?(:controller))
          end
        end
      end

      def blocks(callable_constraint)
        unless callable_constraint.respond_to?(:call) || callable_constraint.respond_to?(:matches?)
          raise ArgumentError, "Invalid constraint: #{callable_constraint.inspect} must respond to :call or :matches?"
        end

        [callable_constraint]
      end

      def canonical_action?(action) #:nodoc:
        resource_method_scope? && Routing::Mapper::CANONICAL_ACTIONS.include?(action.to_s)
      end

      def check_controller_and_action(path_params, controller, action)
        hash = check_part(:controller, controller, path_params, {}) do |part|
          translate_controller(part) {
            message = "'#{part}' is not a supported controller name. This can lead to potential routing problems."
            message << " See http://guides.rubyonrails.org/routing.html#specifying-a-controller-to-use"

            raise ArgumentError, message
          }
        end

        check_part(:action, action, path_params, hash) { |part|
          part.is_a?(Regexp) ? part : part.to_s
        }
      end

      def check_part(name, part, path_params, hash)
        if part
          hash[name] = yield(part)
        else
          unless path_params.include?(name)
            message = "Missing :#{name} key on routes definition, please check your routes."
            raise ArgumentError, message
          end
        end

        hash
      end

      def compiled_path
        pattern = Journey::Path::Pattern.new(@ast, @requirements, JOINED_SEPARATORS, @anchor)

        # Find all the symbol nodes that are adjacent to literal nodes and alter
        # the regexp so that Journey will partition them into custom routes.
        @ast.find_all { |node|
          next unless node.cat?

          if node.left.literal? && node.right.symbol?
            symbol = node.right
          elsif node.left.literal? && node.right.cat? && node.right.left.symbol?
            symbol = node.right.left
          elsif node.left.symbol? && node.right.literal?
            symbol = node.left
          elsif node.left.symbol? && node.right.cat? && node.right.left.literal?
            symbol = node.left
          else
            next
          end

          if symbol
            symbol.regexp = /(?:#{Regexp.union(symbol.regexp, '-')})+/
          end
        }

        pattern
      end

      def constraints(options, path_params)
        options.group_by do |key, option|
          if Regexp === option
            :constraints
          else
            if path_params.include?(key)
              :path_params
            else
              :required_defaults
            end
          end
        end
      end

      def dispatcher(raise_on_name_error)
        Routing::RouteSet::Dispatcher.new raise_on_name_error
      end

      def format_options(options, formatted, path_params, ast, modyoule)
        # Add a constraint for wildcard route to make it non-greedy and match the
        # optional format part of the route by default
        if formatted != false
          options = ast.grep(Journey::Nodes::Star).each_with_object({}) { |node, hash|
            hash[node.name.to_sym] ||= /.+?/
          }.merge options
        end

        # Normalize options:
        if path_params.include?(:controller)
          raise ArgumentError, ":controller segment is not allowed within a namespace block" if modyoule

          # Add a default constraint for :controller path segments that matches namespaced
          # controllers with default routes like :controller/:action/:id(.:format), e.g:
          # GET /admin/products/show/1
          # => { controller: 'admin/products', action: 'show', id: '1' }
          options[:controller] ||= /.+?/
        end

        if @to.respond_to?(:call)
          options
        else
          to_endpoint = @to =~ /#/ ? @to.split('#') : []
          controller  = to_endpoint[0] || @default_controller
          action      = to_endpoint[1] || @default_action

          controller = add_controller_module(controller, modyoule)

          options.merge! check_controller_and_action(path_params, controller, action)
        end

        options
      end

      def format_path(action, _path, formatted)
        path = path_for_action(action, _path)
        raise ArgumentError, "path is required" if path.blank?
        path = normalize_path URI.parser.escape(path), formatted
        path
      end

      # Query if the following named route was already defined.
      def has_named_route?(name)
        @route_set.named_routes.key? name
      end

      def name_for_action(as, action) #:nodoc:
        prefix = prefix_name_for_action(as, action)
        name_prefix = @scope[:as]

        if parent_resource
          return nil unless as || action

          collection_name = parent_resource.collection_name
          member_name = parent_resource.member_name
        end

        action_name = @scope.action_name(name_prefix, prefix, collection_name, member_name)
        candidate = action_name.select(&:present?).join('_')

        unless candidate.empty?
          # If a name was not explicitly given, we check if it is valid
          # and return nil in case it isn't. Otherwise, we pass the invalid name
          # forward so the underlying router engine treats it and raises an exception.
          if as.nil?
            candidate unless candidate !~ /\A[_a-z]/i || has_named_route?(candidate)
          else
            candidate
          end
        end
      end

      def normalize_defaults(options)
        Hash[options.reject { |_, default| Regexp === default }]
      end

      def normalize_format(formatted)
        case formatted
        when true
          { requirements: { format: /.+/ },
            defaults:     {} }
        when Regexp
          { requirements: { format: formatted },
            defaults:     { format: nil } }
        when String
          { requirements: { format: Regexp.compile(formatted) },
            defaults:     { format: formatted } }
        else
          { requirements: { }, defaults: { } }
        end
      end

      def normalize_name(name)
        normalize_journey_path(name)[1..-1].tr("/", "_")
      end

      # Invokes Journey::Router::Utils.normalize_path and ensure that
      # (:locale) becomes (/:locale) instead of /(:locale). Except
      # for root cases, where the latter is the correct one.
      def normalize_journey_path(path)
        path = Journey::Router::Utils.normalize_path(path)
        path.gsub!(%r{/(\(+)/?}, '\1/') unless path =~ %r{^/\(+[^)]+\)$}
        path
      end

      def normalize_path(path, format)
        path = normalize_journey_path(path)

        if format == true
          "#{path}.:format"
        elsif optional_format?(path, format)
          "#{path}(.:format)"
        else
          path
        end

        path
      end

      def optional_format?(path, format)
        format != false && !path.include?(':format') && !path.end_with?('/')
      end

      def path_for_action(action, path) #:nodoc:
        return "#{@scope[:path]}/#{path}" if path

        if canonical_action?(action)
          @scope[:path].to_s
        else
          "#{@scope[:path]}/#{action_path(action)}"
        end
      end

      def parent_resource #:nodoc:
        @scope[:scope_level_resource]
      end

      def prefix_name_for_action(as, action) #:nodoc:
        if as
          prefix = as
        elsif !canonical_action?(action)
          prefix = action
        end

        if prefix && prefix != '/' && !prefix.empty?
          normalize_name prefix.to_s.tr('-', '_')
        end
      end

      def request_method
        @via.map { |x| Journey::Route.verb_matcher(x) }
      end

      def resource_method_scope? #:nodoc:
        @scope.resource_method_scope?
      end

      def split_constraints(path_params, constraints)
        constraints.partition do |key, requirement|
          path_params.include?(key) || key == :controller
        end
      end

      def translate_controller(controller)
        return controller if Regexp === controller
        return controller.to_s if controller =~ /\A[a-z_0-9][a-z_0-9\/]*\z/

        yield
      end

      def verify_regexp_requirements(requirements)
        requirements.each do |requirement|
          if requirement.source =~ ANCHOR_CHARACTERS_REGEX
            raise ArgumentError, "Regexp anchor characters are not allowed in routing requirements: #{requirement.inspect}"
          end

          if requirement.multiline?
            raise ArgumentError, "Regexp multiline option is not allowed in routing requirements: #{requirement.inspect}"
          end
        end
      end
    end
  end
end
