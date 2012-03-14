$ ->
  
  ###
  # Core Model and Logic 
  ###
    
  class Post extends Backbone.Model
    respond: (response) ->
      p = new Post( value: response )
      @save(
        responses:
          @get( 'responses' ).push( p.cid )
      )
    
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
    initialize: ->
      @id = @model.id
    render: ->
      $(@el).html(@template)
      $(@el).find('#content').text(@model.get('content')).omnipost()
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
        content: 'This is an example post.'
        topic_tags: ''
        rubric_tags: ''
        parents: ''
        responses: ''
      )
      pv = new PostView(model: p)
      $('#assignments').append(pv.render())
      
  
  app_router = new Workspace()
  Backbone.history.start()