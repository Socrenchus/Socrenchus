#  Project: Vote Box
#  Description: A Reddit/Stackoverflow type vote box.
#  Author: Bryan Goldstein
#  License: Proprietary

``
(($, window, document) ->

  pluginName = 'notify'
  defaults =
    notificationCount: 0
    position: 'topleft'
    messages: []
  states = 
    none: 0
    open: 1
  class Plugin
    constructor: (@element, options) ->
      @options = $.extend {}, defaults, options
      @_defaults = defaults
      @_name = 'notify'
      @_states = states
      @init()
    
    init: ->
      @state = @_states.none
      template = "<h3 id='notification-counter' title='Notifications'>
                    {{notificationCount}}
                   </h3>
                   <div id='notification-box'></div>
                  "
      templatedata = {notificationCount: @options.notificationCount }
      html = Mustache.to_html(template, templatedata)
      $(@element).html(html)
      notifycounter = $(@element).find("#notification-counter")
      @notifypanel = $(@element).find("#notification-box")
      @notifypanel.hide()
      @addMessages()
      
      notifycounter.click( (event) =>
        @notifypanel.fadeToggle("slow")        
        if @state is @_states.none
          @state = @_states.open
        else if @state is @_states.open
          @state = @_states.none
          @options.notificationCount = 0
          @init()
          @notifypanel.load()
        $(@element).trigger('notifyClicked', @state)
        event.stopPropagation()
      )
      
      $(document).click( =>
        @notifypanel.hide()
        @state = @_states.none
        $(@element).trigger('documentClicked', @state)
      )

      @notifypanel.load( =>
        if @options.position is 'lefttop'
          @notifypanel.css("left", notifycounter.outerWidth())
          @notifypanel.css("top", -notifycounter.outerHeight())
        else if @options.position is 'topright'
          @notifypanel.css("left", -@notifypanel.width() + notifycounter.outerWidth())
        else if @options.position is 'righttop'
          @notifypanel.css("left", -@notifypanel.width())
          @notifypanel.css("top", -notifycounter.outerHeight())
        else if @options.position is 'bottomright'
          @notifypanel.css("left", -@notifypanel.width() + notifycounter.outerWidth())
          @notifypanel.css("top", -@notifypanel.height() - notifycounter.outerHeight())
        else if @options.position is 'rightbottom'
          @notifypanel.css("left", -@notifypanel.width())
          @notifypanel.css("top", -@notifypanel.height())
        else if @options.position is 'bottomleft'
          @notifypanel.css("left", 0)
          @notifypanel.css("top", -@notifypanel.height() - notifycounter.outerHeight())
        else if @options.position is 'leftbottom'
          @notifypanel.css("left", notifycounter.outerWidth())
          @notifypanel.css("top", -@notifypanel.height())
      )
    
    addMessages: =>
      for message in @options.messages
        messagediv = $("<li class='notify-message'>#{message}</li>")
        @notifypanel.append(messagediv)
      params = { messages: @options.messages, messagecount:     @options.notificationCount }
      $(@element).trigger('messagesadded', params)

  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(this, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new Plugin(@, options))
)(jQuery, window, document)
