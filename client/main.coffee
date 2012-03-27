$ ->
  
  ###
  # Core Model and Logic 
  ###
    
  class Post extends Backbone.Model
    respond: (response) ->
      
      p = new Post(
        editing: false
        content: response.posttext
        linkedcontent: response.linkdata
        votecount: 0
        tags: ["kaiji", "san"]
        parents: ''
        responses: ''
      )
      pv = new PostView(model: p)
      $('#assignments').append(pv.render())
      #@save(
      #  responses:
      #    @get( 'responses' ).push( p.cid )
      #)
    
  class Posts extends Backbone.Collection
    model: Post
    localStorage: new Store('posts')
    
  ###
  # View
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
      
    renderPostContent: ->
      postcontentdiv = $("<div class = 'ui-postcontent'></div>")
      postcontentdiv.append(@model.get('linkedcontent'))
      postcontentdiv.append('<br />')
      postcontentdiv.append(@model.get('content'))
      $(@el).find('.inner-question').append(postcontentdiv)
    
    render: ->
      $(@el).html(@template)
      $(@el).find('.inner-question').votebox({votesnum:@model.get('votecount')})
      @renderPostContent()
      $(@el).find('.inner-question').tagbox({editing: true, tags:@model.get('tags')})
      $(@el).find('.inner-question').omnipost({callback: @model.respond, editing:true})
      
      return $(@el)
        
  class StreamView extends Backbone.View
    initialize: ->
      postCollection.bind('add', @addOne, this)
      postCollection.bind('reset', @addAll, this)
      postCollection.fetch()
    addOne: (item) ->
      post = new PostView(model: item)
      #parents = ()
      $(post.render()).appendTo()
    addAll: ->
      postCollection.each(@addOne)
  
  postCollection = new Posts()
  App = new StreamView(el: $('#learn'))
    
  ###
  # Routes
  ###
  class Workspace extends Backbone.Router
    routes:
      '/:id' : 'assign'
      'mockup': 'mockup'
    assign: (id) ->
      postCollection.get(id)
      postCollection.fetch()
    mockup: ->
      p = new Post(
        editing: false
        content: 'This is an example post.'
        linkedcontent: '<img src = "http://m-27.com/wp-content/lol/kaiji.jpg" width = "300" heigh = "auto">'
        votecount: 25
        tags: ["kaiji", "san"]
        parents: ''
        responses: ''
      )
      pv = new PostView(model: p)
      $('#assignments').append(pv.render())
      p1 = new Post(
        editing: false
        content: 'This is an example post.'
        linkedcontent: '<a href = "http://www.imdb.com">www.imdb.com</a>'
        tags: ["do", "re", "mi", "fa", "so"]
        parents: ''
        responses: ''
      )
      pv1 = new PostView(model: p1)
      $('#assignments').append(pv1.render())
      
  
  app_router = new Workspace()
  Backbone.history.start()
