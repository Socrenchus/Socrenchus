#  Project: Submit View
#  Description: A text area with default text and an element that is shown on focus.
#  Author: Bryan Goldstein
#  License: Proprietary

``
(($, window, document) ->
  
  pluginName = 'submitView'
  defaults =
    tools: $()

  class Plugin
    constructor: (@element, options) ->
      @options = $.extend {}, defaults, options

      @_defaults = defaults
      @_name = 'submitView'

      @init()

    init: ->
      @element = $(@element)
      @element.focusin( =>
        unless @element.attr('readonly')?
          @options['tools'].show()
        @element.removeClass('defaultTextActive')
        if @element.val() is @element.attr('title')
          @element.text('')
      ).focusout( =>
        if @element.val() is ''
          @options['tools'].hide()
          @element.text(@element.attr('title'))
          @element.addClass('defaultTextActive')
      ).focusout()
      

  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(this, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new Plugin(@, options))
)(jQuery, window, document)