#  Project: Vote Box
#  Description: A Reddit/Stackoverflow type vote box.
#  Author: Bryan Goldstein
#  License: Proprietary

``
(($, window, document) ->

  pluginName = 'votebox'
  defaults =
    votesnum: 0
    callback: null
    vote: null
    local: false
  states = 
    none: 0
    up: 1
    down: 2
  class Plugin
    constructor: (@element, options) ->
      @options = $.extend {}, defaults, options
      @_defaults = defaults
      @_name = 'votebox'
      @_states = states
      @init()
    
    init: ->
      @dirprefix = '/'
      if @options.local
        @dirprefix = ''
      template = "<img alt='^' title='vote up' id='ui-upvote' />
                  <div id='ui-votetext'>{{votes}}</div>
                  <img alt='v' title='vote down' id='ui-downvote'>"
      @state = @_states.none
      uppressed = false
      downpressed = false
      originalvotesnum = @options.votesnum
      $(@element).bind('updateScore', @updateScore)
      
      templatedata = {votes: Math.round(originalvotesnum) }
      html = Mustache.to_html(template, templatedata)
      $(@element).html(html)

      @upArrow = $(@element).find('#ui-upvote')
      @upArrow.attr('onmouseover', 'src="' + @dirprefix + 'images/votearrowover.png"')
      @upArrow.attr('onmousedown', 'src="' + @dirprefix + 'images/votearrowdown.png"')
      @votetext = $(@element).find('#ui-votetext')
      @downArrow = $(@element).find('#ui-downvote')
      @downArrow.attr('onmouseover', 'src="' + @dirprefix + 'images/votearrowover.png"')
      @downArrow.attr('onmousedown', 'src="' + @dirprefix + 'images/votearrowdown.png"')
      @setImages()
      if @options.vote is true
        @pressUp()
        @disable()
      else if @options.vote is false
        @pressDown()
        @disable()
      else        
        @votetext.text('')
        @upArrow.click( =>
          @pressUp()
        )
        @downArrow.click( =>
          @pressDown()
        )
    
    pressUp: =>
      @state = @_states.up
      @votetext.text(Math.round(@voteCount()))
      voteParams = {'votetext':@votetext.text(), 'votecount':Math.round(@voteCount()).toString()}
      $(@element).trigger('votetextChanged', voteParams)
      @setImages()
      if @state is @_states.up
        @disable()
        unless @options.callback is null
          if @options.vote is null
            @options.callback(",correct")
      $(@element).trigger('upArrowPressed', @state)
    
    pressDown: =>
      @state = @_states.down
      @votetext.text(Math.round(@voteCount()))
      voteParams = {'votetext':@votetext.text(), 'votecount':Math.round(@voteCount()).toString()}
      $(@element).trigger('votetextChanged', voteParams)
      @setImages()
      if @state is @_states.down
        @disable()
        unless @options.callback is null
          if @options.vote is null
            @options.callback(",incorrect")          
      $(@element).trigger('downArrowPressed', @state)

    setImages: =>
      if @state is @_states.down
        @downArrow.attr('src', @dirprefix + 'images/votearrowcomplete.png')
        @downArrow.attr('onmouseout', 'src="' + @dirprefix + 'images/votearrowcomplete.png"')
        @downArrow.attr('onmouseup', 'src="' + @dirprefix + 'images/votearrowcomplete.png"')
        @upArrow.attr('src', @dirprefix + 'images/votearrow.png')
        @upArrow.attr('onmouseout', 'src="' + @dirprefix + 'images/votearrow.png"')
        @upArrow.attr('onmouseup', 'src="' + @dirprefix + 'images/votearrow.png"')
      else if @state is @_states.up
        @upArrow.attr('src', @dirprefix + 'images/votearrowcomplete.png')
        @upArrow.attr('onmouseout', 'src="' + @dirprefix + 'images/votearrowcomplete.png"')
        @upArrow.attr('onmouseup', 'src="' + @dirprefix + 'images/votearrowcomplete.png"')
        @downArrow.attr('src', @dirprefix + 'images/votearrow.png')
        @downArrow.attr('onmouseout', 'src="' + @dirprefix + 'images/votearrow.png"')
        @downArrow.attr('onmouseup', 'src="' + @dirprefix + 'images/votearrow.png"') 
      else if @state is @_states.none 
        @upArrow.attr('src', @dirprefix + 'images/votearrow.png')
        @upArrow.attr('onmouseout', 'src="' + @dirprefix + 'images/votearrow.png"')
        @upArrow.attr('onmouseup', 'src="' + @dirprefix + 'images/votearrow.png"')
        @downArrow.attr('src', @dirprefix + 'images/votearrow.png')
        @downArrow.attr('onmouseout', 'src="' + @dirprefix + 'images/votearrow.png"')
        @downArrow.attr('onmouseup', 'src="' + @dirprefix + 'images/votearrow.png"') 

    disable: =>
      @upArrow.attr('disabled', 'disabled')
      @downArrow.attr('disabled', 'disabled')
      @upArrow.unbind('click')
      @downArrow.unbind('click')
      @upArrow.removeAttr('onmouseout')
      @upArrow.removeAttr('onmouseup')
      @upArrow.removeAttr('onmouseover')
      @upArrow.removeAttr('onmousedown')
      @downArrow.removeAttr('onmouseout')
      @downArrow.removeAttr('onmouseup')
      @downArrow.removeAttr('onmouseover')
      @downArrow.removeAttr('onmousedown')

    voteCount: (newVotesNum=null) =>
      if newVotesNum is null
        return @options.votesnum
      else
        return @options.votesnum = newVotesNum
	  
    getState: =>
      return @options.pressState

    updateScore: (event, newscore) =>
      @voteCount(newscore)
      @votetext.text(Math.round(@voteCount()))
    
    destroy: ->
      $(@element).remove()

  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(this, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new Plugin(@, options))
)(jQuery, window, document)
