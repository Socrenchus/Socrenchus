$ ->
  
  ###
  # Core Models and Logic 
  ###
  class Post extends Backbone.Model
    urlRoot: '/posts'
    initialize: =>
      @view = null
      @level = 0
      @maxlevel = 2
      @relativelevel = 0
      @currentlevel = 0
      
    calcDepth: =>
      parentposts = postCollection.where({id:@get('parent')})
      if parentposts.length > 0
        @level = parentposts[0].level + 1
        @relativelevel = parentposts[0].relativelevel + 1
        parentposts = postCollection.where({id:parentposts[0].get('parent')})
      else
        @level = 0
        @relativelevel = 0

    respond: (content) =>
      p = new Post(
        parent: @get('id')
        content: content
      )
      postCollection.create(p)
      postCollection.fetch()

    maketag: (content) =>
      t = new Tag(
        parent: @get('id')
        title: content
        xp: 0
      )
      tagCollection.create(t)
      
    
  class Posts extends Backbone.Collection
    model: Post
    url: '/posts'

  class Tag extends Backbone.Model
    respond: (content) =>
      t = new Tag(
        title: content
        xp: 0
      )
      tagCollection.create(t)
      
    
  class Tags extends Backbone.Collection
    model: Tag
    url: '/tags'

  ###
  # Views
  ###
  
  Templates = {}
  Templates[e.id] = $(e).html() for e in $('#templates').children()
  
  class PostView extends Backbone.View
    tagName: 'li'
    className: 'post'
    template: Templates.post
    events: ->
      
    initialize: ->
      @id = @model.id
      @model.bind('change', @render)
      @model.view = @      
      @overflowing = false

    renderPostContent: =>
      jsondata = jQuery.parseJSON(@model.get('content'))
      postcontentdiv = $("<div class = 'ui-postcontent'></div>")
      postcontentdiv.append($(jsondata.linkdata))
      postcontentdiv.append('<br />')
      postcontentdiv.append(jsondata.posttext)
      $(@el).find('.inner-question').append(postcontentdiv)
    
    renderProgressBar: => 
      if postCollection.where({parent: @id}).length > 0
        lockedpostsdiv = $("<div class='locked-posts'></div>")
        progressbardiv = $("<div class='progressbar'></div>")
        percent = @model.get('progress') * 100
        textinline = true
        indicatortext = $('<p id="indicator-text">Unlock More Posts</p>')
        if percent < 100.0/350.0 * 100
          textinline = false
        if textinline
          progressindicatordiv = $("<div class='progress-indicator' style='width:#{percent}%'></div>")
          progressindicatordiv.append(indicatortext)          
          progressbardiv.append(progressindicatordiv)
        else
          progressindicatordiv = $("<div class='progress-indicator' style='width:#{percent}%'></div>")          
          progressbardiv.append(progressindicatordiv)
          progressbardiv.append(indicatortext)            
        lockedpostsdiv.append(progressbardiv)
        $(@el).find('.inner-question').append(lockedpostsdiv)

    renderInnerContents: =>
      $(@el).find('.inner-question').votebox({votesnum:@model.get('score'), callback: @model.maketag})
      @renderPostContent()
      $(@el).find('.inner-question').tagbox({callback: @model.maketag})
      @renderProgressBar()
      unless postCollection.where({parent: @id}).length > 0
        $(@el).find('.inner-question').omnipost({removeOnSubmit: true, callback: @model.respond})
      responsediv = $("<div id = 'response#{@model.get('id')}'></div>")
      responsediv.css('border-left', 'dotted 1px black')
      $(@el).find('.inner-question').append(responsediv)

    renderLineToParent: =>
      x1 = $(@el).find('.inner-question').offset().left
      #FIXME: figure out why the top is not quite correct
      y1 = $(@el).find('.inner-question').offset().top + 50
      x2 = $('#' + @model.get('parent')).offset().left + $('#' + @model.get('parent')).width()
      #FIXME: figure out why the top is not quite correct
      y2 = $('#'+@model.get('parent')).offset().top + 
      $('#'+@model.get('parent')).height() + 50
      linediv = $("<img src='/images/diagonalLine.png'></img>")
      linediv.css("position", "absolute")
      linediv.css("left", x1)
      linediv.css("top", y1)
      linediv.css("width", x2 - x1)
      linediv.css("height", y2 - y1)
      linediv.css("z-index", 0)
      $('body').append(linediv)

    render: =>
      $(@el).html(@template)
      $(@el).find('.inner-question').attr('id', @model.get('id'))
      @renderInnerContents()
      return $(@el)
     
   class TagView extends Backbone.View
    tagName: 'p'
    className: 'tag'
    template: Templates.post
    events: ->
      
    initialize: ->
      @id = @model.get('parent')

    render: ->
      tagdiv = $("<div class = 'ui-tag'>#{@model.get('title')}</div>")
      tagdiv.css('background-image', 'url("/images/tagOutline.png")')
      tagdiv.css('background-repeat', 'no-repeat')
      tagdiv.css('background-size', '100% 100%')
      $(@el).append(tagdiv)
   
  class StreamView extends Backbone.View
    initialize: ->
      @streamviewRendered = false
      @selectedStory = '#story-part1'
      postCollection.bind('add', @addOne, this)
      postCollection.bind('reset', @addAll, this)
      postCollection.bind('all', @render, this)
      tagCollection.bind('add', @addTag, this)
      tagCollection.bind('reset', @addAllTags, this)
      postCollection.fetch()
      tagCollection.fetch()

    makePost: (content) ->
      p = new Post(
        content: content
      )
      postCollection.create(p)

    addOne: (item) =>
      post = new PostView(model: item)
      item.calcDepth()
      if item.relativelevel == item.maxlevel
        post.overflowing = true
        item.relativelevel = 0
        
      if !document.getElementById(item.get('id'))
        if document.getElementById('response' + item.get('parent')) and !post.overflowing
          $('#response' + item.get('parent')).prepend(post.render())
        else      
          $('#assignments').prepend(post.render())
      else
        post.renderProgressBar()

    addLines: (item) ->
      if item.view.overflowing
        item.view.renderLineToParent()

    addAll: ->
      postCollection.each(@addOne)
      postCollection.each(@addLines)
    deleteOne: (item) ->
      item.destroy()
    deleteAll: ->
      postCollection.each(@deleteOne)

    addTag: (item) ->
      tag = new TagView(model: item)
    
    addAllTags: ->
      tagCollection.each(@addTag)
    
    showTopicCreator: (showing) =>
      if showing
        $('#post-question').show()
      else
        $('#post-question').hide()
        
    render: =>
      if !@streamviewRendered
        $('#post-question').omnipost({callback: @makePost, message: 'Post a topic...'})      
        @scrollingDiv = $('#story')
        $('#collapsible-profile').hide()
        profileshowing = false
        $('#dropdown-panel').click( ->
          profileshowing = !profileshowing
          $('#collapsible-profile').slideToggle("fast", ( ->             
                $(window).trigger('scroll')
            )
          )
        )
        
        if postCollection.length is 0
          $('#dropdown-panel').click()

        $(document).click( =>
          $('#notification-box').hide()
        )

        $('#notification-box').hide()
        $('#notification-counter').click( ->
          event.stopPropagation() 
          $('#notification-box').toggle()
        )

        $(document).ready( -> 
          $(window).trigger('scroll')
        )
         
        unless $('#ui-omniContainer').length is 0
          $('#ui-omniContainer').qtip({
                   content: 'Click here first.',
                   position: {
                      corner: {
                         tooltip: 'leftMiddle',
                         target: 'rightMiddle'
                      }
                   },
                   show: {
                      when: false,
                      ready: false 
                   },
                   hide: false,
                   style: {
                      border: {
                         width: 5,
                         radius: 10
                      },
                      padding: 10, 
                      textAlign: 'center',
                      tip: true, 
                      'font-size': 16,
                      name: 'cream'
                   }
                });

        $('.ui-omnipost:first #ui-omniContainer').focusin( =>
          if !@omniboxTipInvisible                
            $('#ui-omniContainer').qtip("hide")
          @omniboxTipInvisible = true
        )

        @streamviewRendered = true
        
  ###
  # Routes
  ###
  class Workspace extends Backbone.Router
    routes:      
      'new' : 'new'
      ':id' : 'assign'

    assign: (id) ->
      if id?
        p = new Post({'id':id})
        p.fetch(success:->
          postCollection.add(p)
        )

    new: ->
      App.showTopicCreator(true)

  postCollection = new Posts()
  tagCollection = new Tags()
  App = new StreamView(el: $('#learn'))        
  app_router = new Workspace()  
  Backbone.history.start()
