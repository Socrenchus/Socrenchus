$ ->
  
  ###
  # Core Model and Logic 
  ###
    
  class Post extends Backbone.Model
    respond: (response) =>
      p = new Post(
        parentID: @id
        id: '' + @id + @get('responses').length
        editing: false
        content: response.posttext
        linkedcontent: response.linkdata
        votecount: 0
        tags: ["kaiji", "san"]
        parents: [@id]
        responses: []
      )
      responseArray = @get('responses')
      responseArray.push(p.get('id'))
      @save({responses: responseArray})
      postCollection.create(p)
      
    
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
      postcontentdiv.append($(@model.get('linkedcontent')))
      postcontentdiv.append('<br />')
      postcontentdiv.append(@model.get('content'))
      $(@el).find('.inner-question').append(postcontentdiv)
    
    render: ->
      $(@el).html(@template)
      $(@el).find('.inner-question').votebox({votesnum:@model.get('votecount')})
      @renderPostContent()
      $(@el).find('.inner-question').tagbox({editing: true, tags:@model.get('tags')})
      $(@el).find('.inner-question').omnipost({callback: @model.respond, editing:true})
      responsediv = $("<div id = 'response#{@id}'></div>")
      $(@el).find('.inner-question').append(responsediv)
      if @model.get('parents').length is 0
        lockedpostsdiv = $("<div class='locked-posts'></div>")
        progressbardiv = $("<div class='progressbar'></div>")
        percent = Math.floor(Math.random()*100)
        textinline = true
        indicatortext = $('<p>Unlock ' + Math.floor(2+Math.random() * 7) + ' posts</p>')
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
        
  class StreamView extends Backbone.View
    initialize: ->
      postCollection.bind('add', @addOne, this)
      postCollection.bind('reset', @addAll, this)
      postCollection.bind('all', @render, this)
      postCollection.fetch()
    addOne: (item) ->
      post = new PostView(model: item)
      if document.getElementById('response' + item.get('parentID'))
        $('#response' + item.get('parentID')).prepend(post.render())
      else      
        $('#assignments').append(post.render())
      # parents = ()
      # $(post.render()).appendTo()
    addAll: ->
      postCollection.each(@addOne)
    deleteOne: (item) ->
      item.destroy()
    deleteAll: ->
      postCollection.fetch()
      postCollection.each(@deleteOne)
    render: ->
      $('#collapseable-profile').hide()
      $('#dropdown-panel').click( ->
        $('#collapseable-profile').slideToggle("fast")
      )

      $('#notification-box').hide()
      $('#notification-counter').click( ->
        $('#notification-box').toggle()
      )
    
  ###
  # Routes
  ###
  class Workspace extends Backbone.Router
    routes:
      '/:id' : 'assign'
      'unpopulate' : 'unpopulate'
      'populate' : 'populate'
    assign: (id) ->
      postCollection.get(id)
      postCollection.fetch()

    unpopulate: ->
      App.deleteAll()

    populate: ->
      p = new Post(
        id: 1
        editing: false
        content: 'This is an example post.'
        linkedcontent: '<img src = "http://m-27.com/wp-content/lol/kaiji.jpg" width = "350" height = "auto">'
        votecount: 25
        tags: ["kaiji", "san"]
        parents: ''
        responses: []
      )
      postCollection.create(p)
      p1 = new Post(
        id: 2
        editing: false
        content: 'This is an example post.'
        linkedcontent: '<a href = "http://www.imdb.com">www.imdb.com</a>'
        tags: ["do", "re", "mi", "fa", "so"]
        parents: ''
        responses: []
      )
      postCollection.create(p1)
      
  
  postCollection = new Posts()
  App = new StreamView(el: $('#learn')) 
  app_router = new Workspace()   
  Backbone.history.start()
