module ActionView
  module Tags
    module AssetsTag
      include ActionView::Tags::Base

      URI_REGEX = %r{^[-a-z]+://|^(?:cid|data):|^//}i

      def image_tag(path, options = {})
        # Check for correct URL syntax:
        unless path =~ URI_REGEX
          path = "/assets/#{path}"
        end

        # Raise is no extension
        has_extension = ['.gif', '.jpg', '.png', '.tif'].any? { |format| path.include?(format) }
        unless has_extension
          raise ArgumentError, 'Improperly formatted image_tag'
        end

        "<img src=" + "'#{path}'" + "#{optionize(options)}>"
      end

      def javascript_include_tag(path, options = {})
        # Check for correct URL syntax:
        unless path =~ URI_REGEX
          path = "/assets/#{path}"
        end

        # Add extension if needed
        unless path.include?('.js')
          path = "#{path}.js"
        end

        "<script src=" + "'#{path}'" + "#{optionize(options)}></script>"
      end

      def stylesheet_link_tag(path, options = {})
        # Check for correct URL syntax:
        unless path =~ URI_REGEX
          path = "/assets/#{path}"
        end

        # Add extension if needed
        unless path.include?('.css')
          path = "#{path}.css"
        end

        "<link href=" + "'#{path}'" + " rel='stylsheet'#{optionize(options)}>"
      end
    end
  end
end
