require 'active_support/concern'

module ActionView
  module Tags
    autoload :Base,      'action_view/tags/base'
    ###
    autoload :AssetsTag, 'action_view/tags/assets_tag'
    autoload :UrlTag,    'action_view/tags/url_tag'
  end
end
