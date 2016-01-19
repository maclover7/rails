#require 'erubis'
require 'tilt'

module ActionView
  class Renderer
    def render(template_file, context = {})
      template = Tilt.new(template_file)
      # Passing in a new Object is required in order
      # to render local variables correctly
      template.render(Object.new, context).delete("\n")
    end
  end
end
