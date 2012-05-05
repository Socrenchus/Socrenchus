$ ->
  
  ###
  # Core Models and Logic 
  ###
  class Post extends Backbone.Model
    urlRoot: '/posts'
    initialize: =>

    depth: => @get('depth')-1

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
      @view.createTag(content)
      @view.updateProgress()
    
  class Posts extends Backbone.Collection
    model: Post
    url: '/posts'

  class Tag extends Backbone.Model
      
    
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
    tags: []
    vote: null
    events: ->
      
    initialize: ->
      @id = @model.id
      @model.bind('change', @render)
      @model.view = @

    renderPostContent: =>
      jsondata = jQuery.parseJSON(@model.get('content'))  
      contentdiv = $(@el).find('#content')

      #contentdiv.append($(jsondata.linkdata))
      contentdiv.val(jsondata.posttext)

    updateProgress: =>
      $(@el).find('#progress-bar:first').progressbar("value", @model.get('score') * 100)

    postDOMrender: =>
      if postCollection.where({parent: @id}).length > 0
        if @model.get('progress') != 1
          $(@el).find('#progress-bar:first').progressbar({value: @model.get('progress') * 100})
      $(@el).find('#content').autosize()

    renderInnerContents: =>
      @renderPostContent()
      unless postCollection.where({parent: @id}).length > 0
        $(@el).find('#omnipost:first').omnipost({removeOnSubmit: true, callback: @model.respond})

    renderLineToParent: =>
      if $('#line' + @model.get('id')).length == 0
        x1 = $('#'+@model.get('id')).offset().left
        #FIXME: figure out why the top is not quite correct
        y1 = $('#'+@model.get('id')).offset().top
        x2 = $('#' + @model.get('parent')).offset().left + $('#' + @model.get('parent')).width()
        #FIXME: figure out why the top is not quite correct
        y2 = $('#'+@model.get('parent')).offset().top + 
        $('#'+@model.get('parent')).height()
        linediv = $("<img id ='line#{@model.get("id")}' src='/images/diagonalLine.png'></img>")
        linediv.css("position", "absolute")
        linediv.css("left", x1)
        linediv.css("top", y1)
        linediv.css("width", x2 - x1)
        linediv.css("height", y2 - y1)
        linediv.css("z-index", 0)
        $('body').append(linediv)

    createTag: (tag) =>
      if tag == ',correct'
        vote = true
      else if tag == ',incorrect'
        vote = false
      else
        $(@el).find('#tagbox:first').trigger('addtag', tag)

    render: =>
      $(@el).html(@template)
      $(@el).find('.inner-question').attr('id', @model.get('id'))
      @renderInnerContents()
      tags = tagCollection.where({parent: @model.get('id')})
      taglist = []
      vote = null
      for tag in tags
        t = tag.get('title')
        if t[0] != ','
          taglist.push(t)
        if t == ',correct'
          vote = true
        else if t == ',incorrect'
          vote = false
      $(@el).find('#votebox:first').votebox(vote: vote, votesnum:@model.get('score'), callback: @model.maketag)
      $(@el).find('#tagbox:first').tagbox(callback: @model.maketag, tags: taglist)
      return $(@el)
      
    addChild:(child) =>
      if (@model.depth() % App.maxlevel) == (App.maxlevel - 1)
        root = @
        while root.parent and (root.model.depth() % App.maxlevel) != 0
          root = root.parent
        base = $(root.el)
        base.before(child.render())
        # TODO: add right angle line to top right of post
        # TODO: change child's style to 'grand piano' down to the right corner
      else
        base = $(@el).find('#response:first')
        base.prepend(child.render())
        
    addTag:(tag) =>
      t = tag.get('title')
      if t[0] != ','
        @tags.push(t)
      if t == ',correct'
        @vote = true
      else if t == ',incorrect'
        @vote = false
      

   
  class StreamView extends Backbone.View
    initialize: ->
      @id = 0
      @maxlevel = 4
      @streamviewRendered = false
      @topic_creator_showing = false
      @selectedStory = '#story-part1'
      postCollection.bind('add', @addOne, this)
      postCollection.bind('reset', @addAll, this)
      postCollection.bind('all', @render, this)
      @reset()
    
    reset: =>
      $.getJSON('/stream', ( (data) ->
        @id = data['id']
        tagCollection.add(data['tags'])
        postCollection.add(data['assignments'])
      ))

    makePost: (content) ->
      p = new Post(
        content: content
      )
      postCollection.create(p)
      postCollection.fetch()

    addOne: (item) =>
      post = new PostView(model: item)
      post.parent = postCollection.where({id: item.get('parent')})
      if post.parent.length > 0
        post.parent = post.parent[0].view
        post.parent.addChild(post)
      else
        $('#assignments').prepend(post.render())
      post.postDOMrender()

    addAll: ->
      b = $('#assignments')
      a = b.clone()
      a.empty()
      b.before(a)
      postCollection.each(@addOne)
      b.remove()

    deleteOne: (item) ->
      item.destroy()
    deleteAll: ->
      postCollection.each(@deleteOne)
    
    setTopicCreatorVisibility: =>
      if @topic_creator_showing
        $('#post-question').show() 
      else
        $('#post-question').hide()

    showTopicCreator: (showing) =>
      @topic_creator_showing = showing
      @setTopicCreatorVisibility()
        
    render: =>
      if !@streamviewRendered
        $('#post-question').omnipost({callback: @makePost, message: 'Post a topic...'})
        @setTopicCreatorVisibility()
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
