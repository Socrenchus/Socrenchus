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
        hidden: false
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
      unless @model.get('hidden')
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
        
  class StreamView extends Backbone.View
    initialize: ->
      @streamviewRendered = false
      @selectedStory = '#story-part1'
      postCollection.bind('add', @addOne, this)
      #postCollection.bind('reset', @addAll, this)
      #postCollection.bind('all', @render, this)
      postCollection.fetch()
      @addAll()
      #@render()

    #FIXME: remove these next few functions after the demo.
    setStoryPart: (storyPart) ->
      $(@selectedStory).css('border-style', 'none')
      $(@selectedStory).css('background', 'none')
      @selectedStory = storyPart
      $(@selectedStory).css('border', '2px solid blue')
      $(@selectedStory).css('background', '#9999FF')
      $(@selectedStory).css('-webkit-border-radius', '8px')
      $(@selectedStory).css(' -moz-border-radius', '8px')
      $(@selectedStory).css('border-radius', '8px')
      $('#story').animate({"marginTop": "#{$(@selectedStory).position().top * -1}px"}, "fast")
    
    storyPart2Done: =>
      @setStoryPart('#story-part3')
      $('.ui-omnipost:first #ui-omniPostSubmit').click()
      $('.progress-indicator:first').css('width', '90%')
      post = postCollection.get(2)
      post.set("hidden", false)
      pv = new PostView({model:post})
      $('.post:first #response1').append(pv.render())
      $('.post:first #response1 .ui-tagbox:eq(1)').qtip({
                 content: 'Click here next.',
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
                    'font-size': 16,
                    name: 'cream'
                 }
      });        
      $('.post:first #response1 .ui-tagbox:eq(1)').click( =>
        $('.post:first #response1 .ui-tagbox:eq(1) .ui-individualtag:first').text('Reggies candy bar ')
        $('.post:first #response1 .ui-tagbox:eq(1) .ui-individualtag:first').typewriter(@storyPart3Done)
      )

    storyPart3Done: =>
      @setStoryPart('#story-part4')
      
      e = jQuery.Event('keydown')
      e.keyCode = 13
      $('.post:first #response1 .ui-tagbox:eq(1) .ui-tagtext').trigger(e)
      $('.post:first #response1 .ui-tagbox:eq(1)').qtip("hide")
      $('.post:first #response1 .ui-omnipost:eq(1)').qtip({
                 content: 'Now click here',
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
                    'font-size': 16,
                    name: 'cream'
                 }
              });
      $('.post:first #response1 .ui-omnipost:eq(1)').focusin( =>
        event.stopPropagation()
        $('.post:first #response1 .ui-omnipost:eq(1) #ui-omniPostVideoAttach').click()
        $('.post:first #response1 .ui-omnipost:eq(1) .ui-videobox .ui-omniPostLink').val('http://www.youtube.com/watch?v=2F_PxO1QJ1c')
        $('.post:first #response1 .ui-omnipost:eq(1) .ui-videobox .ui-omniPostLink').textareatypewriter(@storyPart4Done)
      )

    storyPart4Done: =>
      unless @story4Done
        $('#indicator-text').html('Unlock 3 posts')
        $('.progress-indicator:first').css('width', '30%')
        @setStoryPart('#story-part5')
        for i in [3,4]
          post = postCollection.get(i)
          post.set("hidden", false)
          pv = new PostView({model:post})
          $('.post:first #response1 #response2').append(pv.render())
        $('.post:first #response1 .ui-omnipost:eq(1)').qtip("destroy")
        $('.post:first #response1 .ui-omnipost:eq(1)').remove()
        $('#notification-counter').qtip({
                   content: 'Now click here',
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
                      'font-size': 16,
                      name: 'cream'
                   }
                });
        $('#notification-counter').click( =>        
          $('#notification-counter').qtip("hide")
          unless @notificationClicked
            $('.post:first #response2 .ui-tagbox:eq(1)').qtip({
                     content: 'Now click here',
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
                        'font-size': 16,
                        name: 'cream'
                     }
            });
            @notificationClicked = true
          $('.post:first #response2 .ui-tagbox:eq(1)').click( =>          
            $('.post:first #response2 .ui-tagbox:eq(1)').qtip("destroy")
            $('.post:first #response2 .ui-tagbox:eq(1) .ui-individualtag:first').text('history of candy ')
            $('.post:first #response2 .ui-tagbox:eq(1) .ui-individualtag:first').typewriter(@storyPart5Done)
          )
        )
        @story4Done = true
    
    storyPart5Done: =>
      unless @story5Done
        @setStoryPart('#story-part6')
        e = jQuery.Event('keydown')
        e.keyCode = 13
        $('.post:first #response2 .ui-tagbox:eq(1) .ui-tagtext').trigger(e)
        $('#indicator-text').html('Unlock 5 posts')
        $('.progress-indicator:first').css('width', '80%')
        for i in [5..7]
          post = postCollection.get(i)
          post.set("hidden", false)
          pv = new PostView({model:post})
          $('.post:first #response1').append(pv.render())
        @story5Done = true

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
      postCollection.each(@deleteOne)
    disp: =>
      if !@streamviewRendered
        @scrollingDiv = $('#story')
        $(window).scroll( =>
          windowPosition = $(window).scrollTop()          
          windowHeight = $(window).height()
          scrollDivHeight = @scrollingDiv.height()
          currentElPos = $(@selectedStory).position().top
          #if windowPosition > currentElPos
          #  @scrollingDiv.stop().animate({"marginTop": "#{windowPosition - currentElPos - 10}px"}, "fast")
          #if windowPosition is 0
          #  @scrollingDiv.stop().animate({"marginTop": "0px"}, "fast")
        )
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

        $('.ui-omnipost:first #ui-omniContainer').focusin( =>
          if !@omniboxTipInvisible                
            #$('#ui-omniContainer').qtip('api').updateContent('Click the icons to add content such as links, images or video.')
            $('#ui-omniContainer').qtip("hide")
            @setStoryPart('#story-part2')
            $('.ui-omnipost:first #ui-omniPostText').val('I remember my mother cooking breakfast while my sister, my father, and I listened to the radio as FDR began another one of his fireside chats. It was september of 1939 and the topic was the European War.')
            $('.ui-omnipost:first #ui-omniPostText').textareatypewriter(@storyPart2Done)
          @omniboxTipInvisible = true
        )

        $(document).click( ->
          #unless event.target is $('.ui-omnipost:first')               
          #  $('#ui-omniContainer').qtip('hide')
        )  
        @streamviewRendered = true
        
  ###
  # Routes
  ###
  class Workspace extends Backbone.Router
    routes:
      #'/:id' : 'assign'
      ''  : 'normal'
      'unpopulate' : 'unpopulate'
      'populate' : 'populate'
    #assign: (id) ->
    #  postCollection.get(id)
    #  postCollection.fetch()

    deleteOne: (item) ->
      item.destroy()

     normal: ->
      postCollection.fetch()
      postCollection.each(@deleteOne)
      postCollection.reset()
      $('#assignments').html('')
      data = {posttext: 'What is your earliest memory of WWII?', linkdata: '<img src = "http://www.historyplace.com/unitedstates/pacificwar/2156.jpg" width = "350" height = "auto">'}
      p = new Post(
        id: 1
        editing: false
        content: data
        votecount: 25
        tags: ["world war II"]
        parents: ''
        responses: []
        hidden: false
      )
      postCollection.create(p)

      data1 = {posttext: 'Does anyone remember these delicious candybars?', linkdata: '<iframe width="350" height="275" src="http://www.youtube.com/embed/PjcDkdfe6tg" frameborder="0" allowfullscreen></iframe>'}
      p1 = new Post(
        id: 2
        editing: false
        content: data1
        votecount: 13
        tags: ["Reggies candy bar"]
        parents: [p]
        responses: []
        hidden: true
      )
      postCollection.create(p1)

      data2 = {posttext: '', linkdata: '<iframe width="350" height="275" src="http://www.youtube.com/embed/2F_PxO1QJ1c" frameborder="0" allowfullscreen></iframe>'}
      p2 = new Post(
        id: 3
        editing: false
        content: data2
        votecount: 4
        tags: ["Reggies candy bar, World war II"]
        parents: [p1]
        responses: []
        hidden: true
      )
      postCollection.create(p2)

      data3 = {posttext: 'Wow, I completely forgot about this candy.  Its part of a candy wrapper museum now.', linkdata: '<a href="http://www.candywrappermuseum.com/reggiejackson.html">Candy Bar Museum</a>'}
      p3 = new Post(
        id: 4
        editing: false
        content: data3
        votecount: 3
        tags: ["Reggies candy bar, World war II"]
        parents: [p1]
        responses: []
        hidden: true
      )
      postCollection.create(p3)

      data4 = {posttext: 'I remember the first time I heard about the war, I couldnt believe my ears.  I drove to my Mothers house to be sure I saw her at least once before I might have been drafted.', linkdata: ''}
      p4 = new Post(
        id: 5
        editing: false
        content: data4
        votecount: 19
        tags: ["World war II, Heartwarming"]
        parents: [p]
        responses: []
        hidden: true
      )
      postCollection.create(p4)

      data5 = {posttext: 'i wasnt born yet.. im still waiting for WWIII.', linkdata: ''}
      p5 = new Post(
        id: 6
        editing: false
        content: data5
        votecount: -4
        tags: ["disrespectful, immature"]
        parents: [p]
        responses: []
        hidden: true
      )
      postCollection.create(p5)
      
      data6 = {posttext: 'what is World war II?', linkdata: ''}
      p6 = new Post(
        id: 7
        editing: false
        content: data6
        votecount: -6
        tags: ["ignorant"]
        parents: [p]
        responses: []
        hidden: true
      )
      postCollection.create(p6)
      App.disp()

    unpopulate: ->
      postCollection.fetch()
      postCollection.each(@deleteOne)
      postCollection.reset()
      $('#assignments').html('')
      App.disp()

    populate: ->
      postCollection.fetch()
      postCollection.each(@deleteOne)
      postCollection.reset()
      $('#assignments').html('')
      data = {posttext: 'What is your earliest memory of WWII?', linkdata: '<img src = "http://www.historyplace.com/unitedstates/pacificwar/2156.jpg" width = "350" height = "auto">'}
      p = new Post(
        id: 1
        editing: false
        content: data
        votecount: 25
        tags: ["world war II"]
        parents: ''
        responses: []
        hidden: false
      )
      postCollection.create(p)

      data1 = {posttext: 'Does anyone remember these delicious candybars?', linkdata: '<iframe width="350" height="275" src="http://www.youtube.com/embed/PjcDkdfe6tg" frameborder="0" allowfullscreen></iframe>'}
      p1 = new Post(
        id: 2
        editing: false
        content: data1
        votecount: 13
        tags: ["Reggies candy bar"]
        parents: [p]
        responses: []
        hidden: true
      )
      postCollection.create(p1)

      data2 = {posttext: '', linkdata: '<iframe width="350" height="275" src="http://www.youtube.com/embed/2F_PxO1QJ1c" frameborder="0" allowfullscreen></iframe>'}
      p2 = new Post(
        id: 3
        editing: false
        content: data2
        votecount: 4
        tags: ["Reggies candy bar, World war II"]
        parents: [p1]
        responses: []
        hidden: true
      )
      postCollection.create(p2)

      data3 = {posttext: 'Wow, I completely forgot about this candy.  Its part of a candy wrapper museum now.', linkdata: '<a href="http://www.candywrappermuseum.com/reggiejackson.html">Candy Bar Museum</a>'}
      p3 = new Post(
        id: 4
        editing: false
        content: data3
        votecount: 3
        tags: ["Reggies candy bar, World war II"]
        parents: [p1]
        responses: []
        hidden: true
      )
      postCollection.create(p3)

      data4 = {posttext: 'I remember the first time I heard about the war, I couldnt believe my ears.  I drove to my Mothers house to be sure I saw her at least once before I might have been drafted.', linkdata: ''}
      p4 = new Post(
        id: 5
        editing: false
        content: data4
        votecount: 19
        tags: ["World war II, Heartwarming"]
        parents: [p]
        responses: []
        hidden: true
      )
      postCollection.create(p4)

      data5 = {posttext: 'i wasnt born yet.. im still waiting for WWIII.', linkdata: ''}
      p5 = new Post(
        id: 6
        editing: false
        content: data5
        votecount: -4
        tags: ["disrespectful, immature"]
        parents: [p]
        responses: []
        hidden: true
      )
      postCollection.create(p5)
      
      data6 = {posttext: 'what is World war II?', linkdata: ''}
      p6 = new Post(
        id: 7
        editing: false
        content: data6
        votecount: -6
        tags: ["ignorant"]
        parents: [p]
        responses: []
        hidden: true
      )
      postCollection.create(p6)
      App.disp()

  postCollection = new Posts()
  App = new StreamView(el: $('#learn'))        
  app_router = new Workspace()  
  Backbone.history.start()    
