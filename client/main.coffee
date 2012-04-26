$ ->
  
  ###
  # Core Models and Logic 
  ###
  class Post extends Backbone.Model
    respond: (content) =>
      p = new Post(
        parent: @get('id')
        content: content
      )
      postCollection.create(p)

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

    renderPostContent: =>
      jsondata = jQuery.parseJSON(@model.get('content'))
      postcontentdiv = $("<div class = 'ui-postcontent'></div>")
      postcontentdiv.append($(jsondata.linkdata))
      postcontentdiv.append('<br />')
      postcontentdiv.append(jsondata.posttext)
      $(@el).find('.inner-question').append(postcontentdiv)
    
    render: =>
      $(@el).html(@template)
      $(@el).find('.inner-question').votebox({votesnum:@model.get('score'), callback: @model.maketag})
      @renderPostContent()
      tagsdiv = $("<div id='tagscontainer'><div id = 'tags#{@model.get('id')}'></div></div>")      
      $(@el).find('.inner-question').append(tagsdiv)
      #if tagCollection.indexOf('parent: @model.get('id')) > -1
      $(@el).find('.inner-question').tagbox({callback: @model.maketag})
      $(@el).find('.inner-question').omnipost({callback: @model.respond})
      responsediv = $("<div id = 'response#{@model.get('id')}'></div>")
      $(@el).find('.inner-question').append(responsediv)
      unless @model.get('parent') is 0
        lockedpostsdiv = $("<div class='locked-posts'></div>")
        progressbardiv = $("<div class='progressbar'></div>")
        #percent = Math.floor(Math.random()*100)
        percent = 10
        textinline = true
        indicatortext = $('<p id="indicator-text">Unlock ' + Math.floor(1) + ' post</p>')
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

    addOne: (item) ->
      post = new PostView(model: item)
      if document.getElementById('response' + item.get('parent'))
        $('#response' + item.get('parent')).prepend(post.render())
      else      
        $('#assignments').prepend(post.render())

    addAll: ->
      postCollection.each(@addOne)
    deleteOne: (item) ->
      item.destroy()
    deleteAll: ->
      postCollection.each(@deleteOne)

    addTag: (item) ->
      tag = new TagView(model: item)
      #TODO add something when the post has been marked correct or incorrect
      if item.get('title') == ',correct'
        placeholder = 1        
      else if item.get('title') == ',incorrect'
        placeholder = 2
      else if document.getElementById('tags' + item.get('parent')) and item.get('title') != ',assignment'
        $('#tags' + item.get('parent')).append(tag.render())
    
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
        @showTopicCreator(false)        
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
        postCollection.get(id)
        postCollection.fetch()

    deleteOne: (item) ->
      item.destroy()

    new: ->
      App.showTopicCreator(true)

  postCollection = new Posts()
  tagCollection = new Tags()
  App = new StreamView(el: $('#learn'))        
  app_router = new Workspace()  
  Backbone.history.start()
