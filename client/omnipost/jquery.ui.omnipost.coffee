(($, window, document) ->

  pluginName = 'omnipost'
  defaults =
    editing: true
    removeOnSubmit: false
    callback: ''
    message: 'Post your reply here...'
  states =
    none: 0
    open: 1
    
  class Panel
    constructor: (@id, @iconSrc, @collapseSrc, @removalCallBack) ->
      @init()
        
    init: =>
      @slideSpeed = 200
      @panelcontainer = $("<div class=#{@id}></div>")
      @linkIcon = $("<img class = 'ui-panelicon' src = #{@iconSrc} alt = 'attach'>")       
      @collapseIcon = $("<img class = 'ui-panelcollapseicon' src = #{@collapseSrc} alt = 'collapse'>")
      @panelcontainer.append(@linkIcon)
      @panelcontainer.append(@linkbox)     
      @panelcontainer.append(@collapseIcon)
      @panelcontainer.append(@submitLink) 
      @collapseIcon.click( =>
        @remove()
      )

    addPanelToContainer: (container) =>
      container.append(@panelcontainer)
             
    show: =>
      @panelcontainer.show("slide", { direction: "up" }, @slideSpeed)
                      
    hide: =>
      @panelcontainer.hide()
       
    isEmpty: =>
      return @linkbox.val() is ''
  
    remove: =>
      @removalCallBack(this)
      @panelcontainer.remove()

  class LinkPanel extends Panel   
    init: ->
      @maximagewidth = 350;
      super.init()
      @linkbox = $("<textarea class='ui-omniPostLink'></textarea>")
      @submitLink = $("<button class='ui-submitLink'>Add</button>")
      @displayedContent = 'none'
      @attachedImage = $("<img width = '#{@maximagewidth}' height = 'auto' class = 'ui-attachedImage' src = '' alt = 'attach'>")
      @linktosite = $("<a href = #{@linkbox.val()} class = 'ui-linkToSite'></a>")
      @linkedcontentpreview = $("<iframe id='frame' src='' scrolling = no></iframe>")
      @panelcontainer.append(@linkbox)
      @panelcontainer.append(@submitLink)     
      @panelcontainer.append(@attachedImage)
      @panelcontainer.append(@linktosite)
      @panelcontainer.append(@linkedcontentpreview)
      @attachedImage.hide()
      @linkedcontentpreview.hide()
      @linkbox.change( =>
        @displayedContent = 'image'
        @attachedImage.show()
        @linktosite.text('')
        @attachedImage.attr('src', @linkbox.val())
      )
      
      $(document).ready( =>
        @attachedImage.error( =>  
          @attachedImage.hide()
          unless @attachedImage.attr('src') is ''
            @displayedContent = 'link'
            @linktosite.attr('href', @linkbox.val())
            @linktosite.text(@linkbox.val())            
            unless @linktosite.text().indexOf("http://") is 0 
              @linktosite.attr('href', 'http://' + @linktosite.attr('href'))
            @linkedcontentpreview.show()
            @linkedcontentpreview.attr('src', @linktosite.attr('href'))
        )
      )
    
    hide: =>
      super.hide()      
      @linkbox.val('')
      @attachedImage.attr('src', '')
      @linktosite.text('')
      @linkedcontentpreview.attr('src', '')
      @linkedcontentpreview.hide()

    content: =>
      if @displayedContent is 'image'
        return $.trim(@attachedImage[0].outerHTML)
      else if @displayedContent is 'link'
        return $.trim(@linktosite[0].outerHTML)
      else
        return null
 
  class VideoPanel extends Panel
    init: ->
      super.init()
      @linkbox = $("<textarea class='ui-omniPostLink'></textarea>")
      @submitLink = $("<button class='ui-submitLink'>Add</button>")
      @panelcontainer.append(@linkbox)
      @panelcontainer.append(@submitLink)

  class Plugin
    constructor: (@element, options) ->
      @options = $.extend {}, defaults, options
      @_defaults = defaults
      @_name = 'tagbox'
      @_states = states
      @init()
    
    init: ->
      template = "<div id='ui-omniContainer'>
                    <textarea id='ui-omniPostText'></textarea>
                    <img src='/images/collapse.png' alt='x' title='x' id='ui-omniPostCollapse'>
                  </div>
                  <button id='ui-omniPostSubmit'>Post</button>
                 "
      @state = @_states.none
      @panelList = []
      message = @options.message
      $(@element).addClass('ui-omniPost')

      templatedata = {}
      html = Mustache.to_html(template, templatedata)
      $(@element).html(html)

      omnicontainer = $(@element).find('#ui-omniContainer')
      text = $(@element).find('#ui-omniPostText')
      collapse = $(@element).find('#ui-omniPostCollapse')
      post = $(@element).find('#ui-omniPostSubmit')
      
      omnicontainer.click( =>
        unless text.attr('readonly')
          post.show()
          collapse.show()
          text.height(50) if text.height() < 50
        text.removeClass('ui-omniPostActive')
        if text.val() is message
          text.val('')
        text.focus()
        if @state is @_states.none
          @state = @_states.open
        $(@element).trigger('omnicontainerOpened', @state)
      )
      
      collapse.click( (event) =>       
        post.hide()
        text.val(message)
        text.addClass('ui-omniPostActive')
        text.height(28)
        collapse.hide()
        @removeAllPanels()
        $(@element).find('#empty_post_warning').remove()
        event.stopPropagation()
        @state = @_states.none
        $(@element).trigger('omnicontainerClosed', @state)
      )

      collapse.click()
      
      post.click( =>
        unless ($.trim(text.val()) is '')
          allPanelContent = $("<div id='rich-content'></div>")
          for panel in @panelList
            allPanelContent.append(panel.content())
          linkdata = allPanelContent[0].innerHTML
          data = {}
          data['posttext'] = $.trim(text.val())
          data['linkdata'] = linkdata if linkdata
          data = JSON.stringify(data)
          collapse.click()
          if @options.removeOnSubmit
            $(@element).remove()
          @options.callback(data)
        else
          warning = $("<h3 id='empty_post_warning'>You must write something post a reply</h3>")
          if $(@element).find('#empty_post_warning').length == 0
            $(@element).prepend(warning)
      )
  
    removeAllPanels: =>
      removedPanels = []
      for panel in @panelList
        removedPanels.push(panel)
      for panel in removedPanels
        panel.remove()
      $(@element).trigger('panelsChanged', @panelList.length)

    removeElementFromPanelList: (element) =>
      index = @panelList.indexOf(element)
      if index > -1
        @panelList.splice(index, 1)
      $(@element).trigger('panelsChanged', @panelList.length)

    destroy: ->
      $(@element).remove()
    
    _setOption: (option, value) ->
      $.Widget::_setOption.apply(this, arguments)
    
    $.fn[pluginName] = (options) ->
        @each ->
          if !$.data(this, "plugin_#{pluginName}")
            $.data(@, "plugin_#{pluginName}", new Plugin(@, options))
)(jQuery, window, document)
