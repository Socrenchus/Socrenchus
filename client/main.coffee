$ ->
  
  ###
  # Core Models and Logic 
  ###
  class Post extends Backbone.Model
    urlRoot: '/posts'
    initialize: =>     
      @clusters = []
    depth: => @get('depth')-1

    respond: (content) =>
      p = new Post(
        parent: @get('id')
        content: content
      )
      postCollection.create(p)
      postCollection.fetch()
      $('#new-assignment').dialog('close')

    maketag: (content) =>
      t = new Tag(
        parent: @get('id')
        title: content
        xp: 0
      )
      tagCollection.create(t)
      @fetch()
      @view.triggerTagCall(content)
    
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
      @siblingtags = []
      @setSiblingTags() 

    setSiblingTags: =>
      siblings = postCollection.where({parent: @model.get('parent')})
      for sibling in siblings
        taglist = sibling.get('tags')
        if taglist
          for tag in taglist
            if @siblingtags.indexOf(tag) < 0 and tagCollection.where({title:tag}).length == 0
              @siblingtags.push(tag)
      
    renderPostContent: =>
      jsondata = jQuery.parseJSON(@model.get('content'))
      contentdiv = $(@el).find('#content')
      contentdiv.val(jsondata.posttext)

    postDOMrender: =>
      $(@el).find('#content').autosize()
      addthis.toolbox('.addthis_toolbox')

    renderInnerContents: =>
      @renderPostContent()
      unless postCollection.where({parent: @id}).length > 0
        $(@el).find('#replyButton:first').click( =>
          $(@el).find('#replyButton:first').remove()
          $(@el).find('#omnipost:first').omnipost({removeOnSubmit: true, callback: @model.respond})
        )
        questionURL = "http://" + window.location.host + "/#" + @model.get('id')
        $(@el).find('#addThis').attr('addthis:url', questionURL)
      else
        $(@el).find('#replyButton:first').hide()

    triggerTagCall: (tag) =>
      if tag is ",correct" or tag is ",incorrect"
        $(@el).find('#votebox:first').trigger('updateScore', @model.get('score'))

    render: =>
      postcontent = jQuery.parseJSON(@model.get('content'))
      if postcontent.posttext != ''  
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
        
        $(@el).find('#votebox:first').votebox(vote: vote, votesnum:@model.get('score') ? '', callback: @model.maketag)
        $(@el).find('#tagbox:first').tagbox(callback: @model.maketag, tags: taglist, similarTagsStringList: @siblingtags)
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
      tagCollection.fetch()
      postCollection.fetch()
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
      $('#new-assignment').dialog('close')

    makeView: (item) =>
      post = new PostView(model: item)
      post.parent = postCollection.where({id: item.get('parent')})
      if post.parent.length > 0 
        post.parent[0].clusters = post.siblingtags
      return post

    addOne: (item) =>
      post = item.view
      post ? post : post = @makeView(item)
      children = postCollection.where({parent: item.get('id')})
      # render root posts
      if item.depth() is 0
        $('#assignments').prepend(post.render())      
      # render the children posts
      if children.length > 0
        clusters = item.clusters
        if clusters.length == 0
          for child in children
            post.addChild(child.view)
        
        for cluster in clusters
          for child in children
            if child.get('tags').indexOf(cluster) > -1 or child.get('tags').length == 0
              post.addChild(child.view)
        
      post.postDOMrender()

    addAll: ->
      b = $('#assignments')
      a = b.clone()
      a.empty()
      b.before(a)
      postCollection.each(@makeView)
      postCollection.each(@addOne)
      b.remove()

    deleteOne: (item) ->
      item.destroy()
    deleteAll: ->
      postCollection.each(@deleteOne)
    
    createModalReply: (titlemessage, omnimessage, callback) =>
      new_assignment = $('#new-assignment').dialog({title: titlemessage, modal:true, draggable: false, resizable:false, minWidth: 320})
      new_assignment.find('#new-post').omnipost({removeOnSubmit: true, callback: callback, message: omnimessage})

    setTopicCreatorVisibility: =>
      if @topic_creator_showing
        @createModalReply("New Topic", "Post a reply...", @makePost)
      else
        $('#new-assignment').hide()

    showTopicCreator: (showing) =>
      @topic_creator_showing = showing
      @setTopicCreatorVisibility()
        
    render: =>
      if !@streamviewRendered
        #$('#new-assignment').omnipost({callback: @makePost, message: 'Post a topic...'})
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
          postcontent = jQuery.parseJSON(p.get('content'))['posttext']
          App.createModalReply(postcontent, "Post a reply...", p.respond)
        )

    new: ->
      App.showTopicCreator(true)

  postCollection = new Posts()
  tagCollection = new Tags()
  App = new StreamView(el: $('#stream'))        
  app_router = new Workspace()  
  Backbone.history.start()
