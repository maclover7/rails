module ActionView #:nodoc:
  # = Action View PathSet
  #
  # This class is used to store and access paths in Action View. A number of
  # operations are defined so that you can search among the paths in this
  # set and also perform operations on other +PathSet+ objects.
  #
  # A +LookupContext+ will use a +PathSet+ to store the paths in its context.
  class PathSet #:nodoc:
    include Enumerable

    attr_reader :paths

    delegate :[], :include?, :pop, :size, :each, to: :paths

    def initialize(paths = [])
      @paths = typecast paths
    end

    def initialize_copy(other)
      @paths = other.paths.dup
      self
    end

    def to_ary
      paths.dup
    end

    def compact
      PathSet.new paths.compact
    end

    def +(array)
      PathSet.new(paths + array)
    end

    %w(<< concat push insert unshift).each do |method|
      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{method}(*args)
          paths.#{method}(*typecast(args))
        end
      METHOD
    end

    def find(metadata, prefixes)
      find_all_metadata(metadata, prefixes).first || raise(MissingTemplate.new(self, metadata))
    end

    def find_file(metadata, prefixes)
      find_all_metadata(metadata, prefixes).first || raise(MissingTemplate.new(self, metadata, prefixes))
    end

    def find_all(metadata, prefixes)
      find_all_metadata metadata, prefixes
    end

    def exists?(metadata, prefixes)
      find_all_metadata(metadata, prefixes).any?
    end

    def find_all_with_query(query) # :nodoc:
      paths.each do |resolver|
        templates = resolver.find_all_with_query(query)
        return templates unless templates.empty?
      end

      []
    end

    private

      def find_all_metadata(metadata, prefixes)
        prefixes = [prefixes] if String === prefixes
        prefixes.each do |prefix|
          metadata.prefix = prefix
          paths.each do |resolver|
            templates = resolver.find(metadata)
            return templates unless templates.empty?
          end
        end
       []
      end

      def typecast(paths)
        paths.map do |path|
          case path
          when Pathname, String
            ActionView::Resolver::JonResolver.new path.to_s, :optimized
          else
            path
          end
        end
      end
  end
end
