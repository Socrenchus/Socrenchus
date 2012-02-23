#  Project: Vote Box
#  Description: A Reddit/Stackoverflow type vote box.
#  Author: Bryan Goldstein
#  License: Proprietary

``
(($, window, document) ->

  pluginName = 'voteBox'
  defaults =
    property: 'value'

  class Plugin
    constructor: (@element, options) ->
      @options = $.extend {}, defaults, options

      @_defaults = defaults
      @_name = 'voteBox'

      @init()

    init: ->
      # code here

  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(this, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new Plugin(@, options))
)(jQuery, window, document)