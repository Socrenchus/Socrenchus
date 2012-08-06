_.extend( Template.chunk,
  not_root: -> @parent_id?
  groups: ->
    groups = ['all']
    for post in Posts.find( 'parent_id': @parent_id ).fetch()
      tags = (tag for tag of post.tags)
      for tag in tags
        groups.push(tag) unless tag in groups
    return groups
  
  vis_posts: ->
    selected_group = Session.get("group_#{@parent_id}")
    unless selected_group?
      selected_group = 'all'
    posts = []
    for post in Posts.find( 'parent_id': @parent_id ).fetch()
      if selected_group == 'all' || selected_group of post.tags
        posts.push(post._id)
    return posts
"click button[name='post']": (event) ->
      if not event.isPropagationStopped()
        Session.set("reply_#{@parent_id}", event.target.className)
        event.stopPropagation()  
  reply: ->
    reply = Session.get("reply_#{@_id}")
    if reply?
      post = Posts.findOne( _id: reply )
    else
      post = Posts.findOne( parent_id: @_id )
      if post?
        Session.set("reply_#{@_id}", post._id)
    
    return {exists: post?, post: post}
  
  events: {
    "click button[name='group']": (event) ->
      if not event.isPropagationStopped()
        Session.set("group_#{@parent_id}", event.target.className)
        event.stopPropagation()
    
    "click button[name='post']": (event) ->
      if not event.isPropagationStopped()
        Session.set("reply_#{@parent_id}", event.target.className)
        event.stopPropagation()
        
    "click button[name='carousel']": (event) ->
      if not event.isImmediatePropagationStopped()
        console.log('restart')
        #Session.set('carousel_parent', Posts.find(_id: @parent_id))
        carousel_handle = Meteor.setInterval(carousel, 3000)
        Meteor.clearInterval(Session.get('carousel_handle'))
        Session.set('carousel_handle', carousel_handle)
        event.stopImmediatePropagation()
    
    'click': (event) ->
      parent = Session.get('carousel_parent')
      if parent?._id == @parent_id
        console.log('STOP')
        Meteor.clearInterval(Session.get('carousel_handle'))
  }
)
