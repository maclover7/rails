module ActionView
  module Tags
    module UrlTag
      include ActionView::Tags::Base

      def link_to(name, path, options = {})
        options['href'] = path
        options['between_content'] = name
        options['closing_tag'] = true
        tag('a', options)
      end
    end
  end
end
