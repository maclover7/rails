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
    end
  end
end
