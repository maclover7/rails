require 'active_support/core_ext/hash/keys'

module ActionView
  module Tags
    module Base
      def optionize(options)
        output = ''
        sep    = ' '.freeze

        return output if options.empty?

        options.each do |k, v|
          output << sep
          output << "#{k}='#{v}'"
        end

        output
      end

      def tag(tag_name, options)
        options.stringify_keys!
        between_tags = options.delete('between_tags')
        closing_tag = options.delete('closing_tag')
        ###
        output = "<#{tag_name}#{optionize(options)}>"
        output << between_tags if between_tags
        output << "</#{tag_name}>" if closing_tag
        output
      end
    end
  end
end
