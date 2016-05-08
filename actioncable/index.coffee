# Define ActionCable namespace and internal parameters.
ActionCable = 
  INTERNAL: 
    message_types:
      welcome: 'welcome'
      ping: 'ping'
      confirmation: 'confirm_subscription'
      rejection: 'reject_subscription'
    default_mount_path: '/cable'
    protocols: [
      'actioncable-v1-json'
      'actioncable-unsupported'
    ]

# Include other modules in order.
#= require ./app/assets/javascripts/action_cable/connection_monitor.coffee
#= require ./app/assets/javascripts/action_cable/connection.coffee
#= require ./app/assets/javascripts/action_cable/subscriptions.coffee
#= require ./app/assets/javascripts/action_cable/subscription.coffee
#= require ./app/assets/javascripts/action_cable/consumer.coffee

module.exports =
  createConsumer: (url) ->
    new ActionCable.Consumer @createWebSocketURL(url)

  createWebSocketURL: (url) ->
    if url and not /^wss?:/i.test(url)
      a = document.createElement("a")
      a.href = url
      # Fix populating Location properties in IE. Otherwise, protocol will be blank.
      a.href = a.href
      a.protocol = a.protocol.replace("http", "ws")
      a.href
    else
      url

  startDebugging: ->
    @debugging = true

  stopDebugging: ->
    @debugging = null

  log: (messages...) ->
    if @debugging
      messages.push(Date.now())
      console.log("[ActionCable]", messages...)
