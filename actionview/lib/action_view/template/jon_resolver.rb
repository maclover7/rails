module ActionView
  class Resolver # :nodoc:
    class JonResolver
      EXTENSIONS = { locale: ".", formats: ".", variants: "+", handlers: "." }

      def initialize(path, mode = :optimized)
        @path = path
        @mode = mode
      end

      def find(metadata)
        query = build_query(metadata)
        template_files = run_query(query, metadata)
        templates = generate_templates(template_files, metadata)
        templates
      end

      def find_with_query(query)
        run_query(File.join(@path, query), ActionView::Template::TemplateLookupMetadata.new({}))
      end

      private

      def build_optimized_query(metadata)
        query = escape_entry(File.join(@path, metadata.path))

        exts = EXTENSIONS.map do |ext, prefix|
          metadata_info = metadata.public_send(ext)

          if ext == :variants && metadata_info == :any
            "{#{prefix}*,}"
          else
            "{#{metadata_info.compact.uniq.map { |e| "#{prefix}#{e}," }.join}}"
          end
        end.join

        query + exts
      end

      # Helper for building query glob string based on resolver's pattern.
      def build_query(metadata)
        if @mode == :optimized
          build_optimized_query(metadata)
        end
      end

      def escape_entry(entry)
        entry.gsub(/[*?{}\[\]]/, '\\\\\\&'.freeze)
      end

      # Extract handler, formats and variant from path. If a format cannot be found neither
      # from the path, or the handler, we should return the array of formats given
      # to the resolver.
      def extract_handler_and_format_and_variant(path, default_formats)
        pieces = File.basename(path).split(".".freeze)
        pieces.shift

        extension = pieces.pop

        handler = Template.handler_for_extension(extension)
        format, variant = pieces.last.split(EXTENSIONS[:variants], 2) if pieces.last
        format &&= Template::Types[format]

        [handler, format, variant]
      end

      def generate_templates(template_files, metadata)
        template_files.map do |template_path|
          handler, format, variant = extract_handler_and_format_and_variant(template_path, metadata.formats)

          Template.new(
            File.binread(template_path),
            File.expand_path(template_path),
            handler,

            {
              virtual_path: metadata.path.virtual,
              format: format,
              variant: variant,
              updated_at: File.mtime(template_path)
            }
          )
        end
      end

      def inside_path?(path, filename)
        filename = File.expand_path(filename)
        path = File.join(path, "")
        filename.start_with?(path)
      end

      def run_query(query, metadata)
        files = Dir[query].uniq.reject do |filename|
          File.directory?(filename) ||
            # deals with case-insensitive file systems.
            !File.fnmatch(query, filename, File::FNM_EXTGLOB)
        end

        if !metadata.outside_app_allowed
          files.reject { |filename| !inside_path?(@path, filename) }
        end

        files
      end
    end
  end
end
