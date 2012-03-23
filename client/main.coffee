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
    events: ->
      'click button#reply': 'replyToPost'
    initialize: ->
      @id = @model.id
    render: ->
      $(@el).html(@template)
      # $(@el).find('#content').text(@model.get('content')).omnipost()    
      $(@el).find('.inner-question').votebox({votesnum:@model.get('votecount')})
      $(@el).find('.inner-question').omnipost({editing:@model.get('editing'), postcontent:@model.get('content'), linkedcontent:@model.get('linkedcontent')})
      $(@el).find('.inner-question').tagbox({editing: @model.get('editing'), tags:@model.get('tags')})
      $(@el).append("<button id='reply'>Reply</button>");
      
      return $(@el)
    
    replyToPost: ->
      replyPost = new Post(
        editing: true
        content: ''
        linkedcontent: ''
        votecount: 0
        tags: []
        parents: @model
        responses: ''
      )
      replyView = new PostView(model: replyPost)
      $(@el).append(replyView.render())
        
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
        linkedcontent: '<img src="http://m-27.com/wp-content/lol/kaiji.jpg" alt=""/>'
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
        linkedcontent: '<img src="http://m-27.com/wp-content/lol/kaiji.jpg" alt=""/>'
        tags: ["do", "re", "mi", "fa", "so"]
        parents: ''
        responses: ''
      )
      pv1 = new PostView(model: p1)
      $('#assignments').append(pv1.render())
      
  
  app_router = new Workspace()
  Backbone.history.start()
