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
      @tooltipsRendered = false
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
    render: =>
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
                $('#dropdown-panel').attr('src', '/images/dropdownreversed.png')
              else
                $('#tagcloud-img').qtip("hide");
                $('#badges').qtip("hide");
                $('#friends-list').qtip("hide");
                $('#dropdown-panel').attr('src', '/images/dropdown.png')
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
      
      if !@tooltipsRendered
        $('#tagcloud-img').qtip({
                 content: 'This is your tag cloud.  It contains every tag by every person.  The size of the tag shows how often that tag gets used by everyone.  The color of the tag shows how often you use that tag or have it used on you.',
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
                    'font-size': 16,
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
                    'font-size': 16,
                    name: 'cream'
                 }
              });

        $('#notification-counter').click( =>
          if !@notificationTipInvisible
            $('#dropdown-panel').qtip("show");
          $('#notification-counter').qtip("hide");
          @notificationTipInvisible = true
        )

        $('#notification-counter').qtip({
                 content: 'Unviewed Notifications.  Click on it to reveal the notifications.',
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
                   'font-size': 16,
                   name: 'cream'
                 }
        });
             
        $('#dropdown-panel').click( =>
          if !@dropdownTipInvisible            
            $('.ui-votebox:first').qtip("show");
          $('#dropdown-panel').qtip("hide");
          @dropdownTipInvisible = true
        )

        $('#dropdown-panel').qtip({
                 content: 'Click this tab to view you profile.  This includes a list of tags, badges, and friends that use Socrenchus from another website such as facebook.',
                 position: {
                    corner: {
                       tooltip: 'topLeft',
                       target: 'bottomRight'
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

        $('.ui-votebox').click( =>
           if !@voteboxTipInvisible
             $('.ui-tagbox:first').qtip("show");
           $('.ui-votebox:first').qtip("hide");
           @voteboxTipInvisible = true
        )

        # FIXME: remove these next 2 click events once we figure out why the event isn't propagating up to the parent.
        $('.ui-votebox #ui-upvote').click( =>
           if !@voteboxTipInvisible
             $('.ui-tagbox:first').qtip("show");
           $('.ui-votebox:first').qtip("hide");
           @voteboxTipInvisible = true
        )
  
        $('.ui-votebox #ui-downvote').click( =>
           if !@voteboxTipInvisible
             $('.ui-tagbox:first').qtip("show");
           $('.ui-votebox:first').qtip("hide");
           @voteboxTipInvisible = true
        )

        $('.ui-votebox:first').qtip({
                 content: 'Click up or down to set the score of a post.',
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
                    'font-size': 16,
                    name: 'cream'
                 }
              });
          
        $('.ui-tagbox:first').click( =>
           if !@tagboxTipInvisible  
             $('#ui-omniContainer').qtip("show");
           $('.ui-tagbox:first').qtip("hide");
           @tagboxTipInvisible = true        
        )
        $('.ui-tagbox:first').qtip({
                 content: 'You can tag a post with a list of topics.  Tags can be multiple words, and are seperated by pressing enter or the comma key.',
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
                    'font-size': 16,
                    name: 'cream'
                 }
              });
         
        $('.ui-omnipost:first').click( ->
           $('#ui-omniContainer').qtip("hide");
        )

        $('#ui-omniContainer').qtip({
                 content: 'Make a post.  Text, images, and links are already included, and video posting will be included shortly.',
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
          @tooltipsRendered = true
        
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
