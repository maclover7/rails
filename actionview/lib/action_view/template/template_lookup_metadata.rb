module ActionView
  class Template
    class TemplateLookupMetadata < Struct.new(
      :name, :prefix, :is_partial, :cache_key, :locals, :outside_app_allowed,
      :formats, :locale, :variants, :handlers
    )

      DEFAULTS = {
        is_partial: false,
        cache_key: nil,
        locals: [],
        prefix: "",
        name: "",
        outside_app_allowed: false,

        formats: [],
        locale: [],
        variants: [],
        handlers: []
      }

      def initialize(hash)
        hash.merge(DEFAULTS) do |k, v|
          public_send("#{k}=", v)
        end
      end

      def cache_key
        super || [[name][prefix][is_partial][locals]]
      end

      def each
        instance_variables.each do |var|
          yield var, public_send(var)
        end
      end

      def path
        ActionView::Resolver::Path.build(name, prefix, is_partial)
      end
    end
  end
end
