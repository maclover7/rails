require "action_view"
require "rails"

module ActionView
  # = Action View Railtie
  class Railtie < Rails::Railtie # :nodoc:
    config.action_view = ActiveSupport::OrderedOptions.new
    config.action_view.embed_authenticity_token_in_remote_forms = false
    config.action_view.debug_missing_translation = true

    config.eager_load_namespaces << ActionView

    initializer "action_view.embed_authenticity_token_in_remote_forms" do |app|
      ActiveSupport.on_load(:action_view) do
        ActionView::Helpers::FormTagHelper.embed_authenticity_token_in_remote_forms =
          app.config.action_view.delete(:embed_authenticity_token_in_remote_forms)
      end
    end

    initializer "action_view.logger" do
      ActiveSupport.on_load(:action_view) { self.logger ||= Rails.logger }
    end

    initializer "action_view.set_configs" do |app|
      ActiveSupport.on_load(:action_view) do
        app.config.action_view.each do |k,v|
          send "#{k}=", v
        end
      end
    end

    initializer "action_view.caching" do |app|
      ActiveSupport.on_load(:action_view) do
        if app.config.action_view.cache_template_loading.nil?
          ActionView::Resolver.caching = app.config.cache_classes
        end
      end
    end

    initializer "action_view.per_request_digest_cache" do |app|
      ActiveSupport.on_load(:action_view) do
        if app.config.consider_all_requests_local
          app.executor.to_run { ActionView::LookupContext::DetailsKey.clear }
        end
      end
    end

    initializer "action_view.setup_action_pack" do |app|
      ActiveSupport.on_load(:action_controller) do
        ActionView::RoutingUrlFor.include(ActionDispatch::Routing::UrlFor)
      end
    end

    initializer "action_view.collection_caching", after: "action_controller.set_configs" do |app|
      PartialRenderer.collection_cache = app.config.action_controller.cache_store
    end

    initializer "action_view.eager_compile_templates" do |app|
      ActiveSupport.on_load(:action_view) do
        app.config.action_view.eager_compile_templates = true

        return unless app.config.action_view.eager_compile_templates

        puts "Loading data to eager compile templates"

        ctx = ApplicationController.new.lookup_context
        template_paths = []
        templates = []

        # Create a raw list of paths where templates are stored.
        ctx.view_paths.paths.each do |path|
          template_paths << path.instance_variable_get(:@path)
        end

        # Go through the raw list, and create a list of every single template.
        template_paths.each do |path|
          templates.concat Dir.glob("#{path}/**/*").reject {|fn| File.directory?(fn) }
        end

        puts "Data analysis complete! Beginning to eager compile templates (Note: this could take a while)"

        # Go through the list of templates, compile down the raw template code, and cache the result.
        templates.each do |template_path|
          pieces = File.basename(template_path).split(".".freeze)
          pieces.shift
          extension = pieces.pop
          handler = Template.handler_for_extension(extension)

          t = ActionView::Template.new(File.read(template_path), File.expand_path(template_path), handler, {})
          t.send :compile_and_cache
        end

        puts "Eager compilation of templates is complete!"
      end
    end

    rake_tasks do |app|
      unless app.config.api_only
        load "action_view/tasks/cache_digests.rake"
      end
    end
  end
end
