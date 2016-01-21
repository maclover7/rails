require 'active_support/concern'

module ActionView
  module Tags
    autoload :Base,      'action_view/tags/base'
    ###
    autoload :AssetsTag, 'action_view/tags/assets_tag'
  end
end
