require 'active_support/core_ext/hash/keys'

module ActionView
  module Tags
    module Base
      def optionize(options)
        output = ''
        sep    = ' '.freeze

        return output if options.empty?

        options.stringify_keys!
        options.each do |k, v|
          output << sep
          output << "#{k}='#{v}'"
        end

        output
      end

      def tag(tag_name, closing_tag = false, options)
        output = "<#{tag_name}#{optionize(options)}>"
        output << "</#{tag_name}>" if closing_tag
        output
      end
    end
  end
end
