#  Project: Tag Box
#  Description: A StackOverflow type tagbox.
#  Author: Bryan Goldstein and Prayrit Jain
#  License: Proprietary

``
(($, window, document) ->

  pluginName = 'tagbox'
  
  states = 
    none: 0
    typing: 1
    altering: 2        
    
  defaults =
    tags: []
    callback: null
    similarTagsStringList: ['my', 'name', 'is', 'prash', 'mah', 'naem', 'iss', 'prashu']
  class Plugin
    constructor: (@element, options) ->
      @options = $.extend {}, defaults, options
      @_defaults = defaults
      @_states = states
      @state = states.none
      @_name = 'tagbox'
      @init()
    
    init: ->
      template = "<div class='ui-tagmessage'>{{tagmessage}}</div>
                  <div class='ui-individualtag' contentEditable='true'></div>
                  <div id='ui-simtags'></div>
                  "
      @alltags = []
      @similartags = []
      editingoldtag = false
      templatedata = {tagmessage: '+ Add Tags'}
      html = Mustache.to_html(template, templatedata)
      $(@element).html(html)
      @similartagdiv = $(@element).find('#ui-simtags')
      @currenttag = $(@element).find('.ui-individualtag') 
      @message = $(@element).find('.ui-tagmessage')
      $(@element).trigger('tagSync', @currenttag.text())
      
      @similartagdiv.hide()

      @createSimilarTags()

      if @options.tags
        @showTags()

      @currenttag.focusout( =>
        @similartagdiv.hide()
        @message.show()
        @currenttag.text("")
        @showSimilarTags()
        @currenttag.hide()
        @state = @_states.none
        $(@element).trigger('unfocusingTagBox', @state)
      )

      @currenttag.keydown (event) =>
        # if enter or comma is pressed
        if event.keyCode is 13 or event.keyCode is 188
          event.preventDefault()
          @makenewtag()
        
      @currenttag.keyup (event) =>
        @showSimilarTags()

      @message.click( =>
          unless @editingoldtag
            @similartagdiv.show()
            @message.hide()              
            @currenttag.show()
            @currenttag.focus()
            @state = @_states.typing
            $(@element).trigger('typingTag', @state)
      )

    createSimilarTags: =>
      for tag in @options.similarTagsStringList
        currenttag = $("<div class='ui-completetag'>#{tag}</div>")
        currenttag.css('background-image', 'url("/images/tagOutline.png")')
        currenttag.css('background-repeat', 'no-repeat')
        currenttag.css('background-size', '100% 100%')
        @similartagdiv.append(currenttag)
        @similartags.push(currenttag)

    showSimilarTags: =>
      currenttagtext = $.trim(@currenttag.text())
      for tag in @similartags
        if tag.text().indexOf(currenttagtext) == 0
          tag.show()
        else
          tag.hide()

    addTag: (tag) =>
      currenttag = $("<div class='ui-completetag'>#{tag}</div>")
      currenttag.css('background-image', 'url("/images/tagOutline.png")')
      currenttag.css('background-repeat', 'no-repeat')
      currenttag.css('background-size', '100% 100%')
      @message.before(currenttag)

    showTags: (taglist) =>
      for tag in @options.tags
        @addTag(tag)
        
    removeFromArray: (toremove) =>
      index = @alltags.indexOf(toremove)
      if index > -1
        @alltags.splice(index, 1)

    makenewtag: () =>
      @currenttag.text($.trim(@currenttag.text()))
      unless @currenttag.text() is ''
        $(@element).trigger('tagSync', @currenttag.text())
        unless @options.callback is null
          @options.callback(@currenttag.text())
        @addTag(@currenttag.text())
        @currenttag.text('')
        

    formtag: (tagdiv) =>
      @editingoldtag = false
      tagdiv.text($.trim(tagdiv.text()))

      tagdiv.click( =>
         @deformtag(tagdiv)
         state = states.altering
      )
      
      tagdiv.attr('contentEditable', 'false')
      tagdiv.css('background-image', 'url("/images/tagOutline.png")')
      tagdiv.css('background-repeat', 'no-repeat')
      tagdiv.css('background-size', '100% 100%')

    deformtag: (tagdiv) =>
      @editingoldtag = true
      tagdiv.attr('contentEditable', 'true')
      tagdiv.css('background-image', 'none')
      tagdiv.css('background-repeat', 'no-repeat')  
      tagdiv.css('background-size', '100% 100%')
      deleteiconclass = $('.delete-imageicon')
      deleteicon = $(tagdiv.find(deleteiconclass)[0])
      deleteicon.remove()
      @removeFromArray(tagdiv)
      tagdiv.focus()
      @state = @_states.altering
      $(@element).trigger('alteringTag', @state)

    createcompletetags: (tags) =>
      tagsdiv =  $("<div class='ui-tagbox'></div>")
      for tag in tags
        currenttag = $("<div class='ui-individualtag'>#{tag}</div>")
        currenttag.css('background-image', 'url("/images/tagOutline.png")')
        currenttag.css('background-repeat', 'no-repeat')
        currenttag.css('background-size', '100% 100%')
        tagsdiv.append(currenttag)
      $(@element).append(tagsdiv)
    
    getAllTags: =>
      tags = []
      for tag in @alltags
        tags.push(tag.text())
      tags

    maketags: =>
      tags = @getAllTags()
      for tag in tags
        @options.callback(tag)
      for individualTag in @alltags
        individualTag.find('.delete-imageicon').click()
    
    @setCurrentTag: (text) =>
      @currenttag.text(text)

  $.fn[pluginName] = (options) ->
    @each ->
      if !$.data(this, "plugin_#{pluginName}")
        $.data(@, "plugin_#{pluginName}", new Plugin(@, options))
)(jQuery, window, document)
