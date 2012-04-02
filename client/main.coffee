$ ->
  
  ###
  # Core Model and Logic 
  ###
    
  class Post extends Backbone.Model
    respond: (content) =>
      p = new Post(
        parentID: @id
        id: '' + @id + @get('responses').length
        editing: false
        content: content
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
      postcontentdiv.append($(@model.get('content').linkdata))
      postcontentdiv.append('<br />')
      postcontentdiv.append(@model.get('content').posttext)
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
      profileshowing = false
      $('#dropdown-panel').click( ->
        profileshowing = !profileshowing
        $('#collapseable-profile').slideToggle("fast", ( ->             
              $(window).trigger('scroll')
              if profileshowing
                $('#tagcloud-img').qtip("show");
                $('#badges').qtip("show");
                $('#friends-list').qtip("show");
              else
                $('#tagcloud-img').qtip("hide");
                $('#badges').qtip("hide");
                $('#friends-list').qtip("hide");
          )
        )
      )

      $('#notification-box').hide()
      $('#notification-counter').click( ->
        $('#notification-box').toggle()
      )

      $(document).ready( -> 
        $(window).trigger('scroll')
      )
      $('#dropdown-panel').qtip({
               content: 'By clicking this tab, you can view your profile.  This includes a list of your tags, badges, and list of friends that use Socrenchus from another website such as facebook.',
               position: {
                  corner: {
                     tooltip: 'topLeft',
                     target: 'bottomRight'
                  }
               },
               show: {
                  when: false,
                  ready: true 
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
                  name: 'cream'
               }
            });

      $('#tagcloud-img').qtip({
               content: 'This is your tag cloud.  It contains all tags that you have been involved in, where the bigger the tag, the bigger your involvement.',
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
                  name: 'cream'
               }
            });
      $('#badges').qtip({
               content: 'A list of your badges.  Earn more by accomplishing certain tasks',
               position: {
                  corner: {
                     tooltip: 'rightMiddle',
                     target: 'leftMiddle'
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
                  name: 'cream'
               }
            });

      $('#friends-list').qtip({
               content: 'A list of your friends.  These are friends from other websites, such as facebook, that are using Socrenchus.',
               position: {
                  corner: {
                     tooltip: 'rightMiddle',
                     target: 'leftMiddle'
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
                  name: 'cream'
               }
            });

      $('#notification-counter').qtip({
               content: 'This shows you how many unviewed notifications you have.  Clicking on it reveals what those notifications are.',
               position: {
                 corner: {
                    tooltip: 'leftMiddle',
                    target: 'rightMiddle'
                 }
               },
               show: {
                 when: false,
                 ready: true
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
                 name: 'cream'
               }
      });
        
      $('.ui-votebox:first').qtip({
               content: 'Clicking up or down on this UI element will allow you to change the score of the post you are voting on.  In the future, this will take into account your experience in the topic of the answer you are voting on.',
               position: {
                  corner: {
                     tooltip: 'rightMiddle',
                     target: 'leftMiddle'
                  }
               },
               show: {
                  when: false,
                  ready: true 
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
                  name: 'cream'
               }
            });
        
      $('.ui-tagbox:first').qtip({
               content: 'You can tag a post with a list of topics that you deem relavent.  Tags can be multiple words, and are seperated by pressing enter or the comma key.',
               position: {
                  corner: {
                     tooltip: 'rightMiddle',
                     target: 'leftMiddle'
                  }
               },
               show: {
                  when: false,
                  ready: true 
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
                  name: 'cream'
               }
            });
       
      $('#ui-omniContainer').qtip({
               content: 'You can include several forms of content when you make a post.  Text and images are already included, and video posting will be included shortly.',
               position: {
                  corner: {
                     tooltip: 'leftMiddle',
                     target: 'rightMiddle'
                  }
               },
               show: {
                  when: false,
                  ready: true 
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
                  name: 'cream'
               }
            });
        
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
      data = {posttext: 'This is an example post.', linkdata: '<img src = "http://m-27.com/wp-content/lol/kaiji.jpg" width = "350" height = "auto">'}
      p = new Post(
        id: 1
        editing: false
        content: data
        votecount: 25
        tags: ["kaiji", "san"]
        parents: ''
        responses: []
      )
      postCollection.create(p)

      data = {posttext: 'This is an example post.', linkdata: '<a href = "http://www.imdb.com">www.imdb.com</a>'}
      p1 = new Post(
        id: 2
        editing: false
        content: data
        tags: ["do", "re", "mi", "fa", "so"]
        parents: ''
        responses: []
      )
      postCollection.create(p1)
      
  
  postCollection = new Posts()
  App = new StreamView(el: $('#learn')) 
  app_router = new Workspace()   
  Backbone.history.start()
