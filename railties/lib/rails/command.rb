require 'rails/commands/commands_tasks'
require 'active_support/callbacks'

module Rails
  class Command #:nodoc:
    include ActiveSupport::Callbacks
    define_callbacks :run
    
    attr_reader :argv

    def initialize(argv = [])
      @argv = argv

      @option_parser = build_option_parser
      @options = {}
    end

    def self.run(task_name, argv)
      command_name = command_name_for(task_name)

      if command = command_for(command_name)
        command.new(argv).run(command_name)
      else
        Rails::CommandsTasks.new(argv).run_command!(task_name)
      end
    end

    def run(command_name)
      parse_options_for(command_name)
      @option_parser.parse! @argv

      run_callbacks :run do
        public_send(command_name)
      end
    end

    def self.options_for(command_name, &options_to_parse)
      @@command_options[command_name] = options_to_parse
    end

    def self.set_banner(command_name, banner)
      options_for(command_name) { |opts, _| opts.banner = banner }
    end
    
    def after_command(&block)
      set_callback(:after, :run, block)
    end
    
    def before_command(&block)
      set_callback(:before, :run, block)
    end

    private
      @@commands = []
      @@command_options = {}

      def parse_options_for(command_name)
        @@command_options.fetch(command_name, proc {}).call(@option_parser, @options)
      end

      def build_option_parser
        OptionParser.new do |opts|
          opts.on('-h', '--help', 'Show this help.') do
            puts opts
            exit
          end
        end
      end

      def self.inherited(command)
        @@commands << command
      end

      def self.command_name_for(task_name)
        task_name.gsub(':', '_').to_sym
      end

      def self.command_for(command_name)
        @@commands.find do |command|
          command.public_instance_methods.include?(command_name)
        end
      end
  end
end
