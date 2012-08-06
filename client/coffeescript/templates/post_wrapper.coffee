_.extend( Template.post_wrapper,
  not_root: -> @parent_id?
  groups: ->
    groups = ['all']
    for post in Posts.find( 'parent_id': @parent_id ).fetch()
      tags = (tag for tag of post.tags)
      for tag in tags
        groups.push(tag) unless tag in groups
    return groups
  
  group_posts: ->
    selected_group = Session.get("group_#{@parent_id}")
    unless selected_group?
      selected_group = 'all'
    posts = []
    for post in Posts.find( 'parent_id': @parent_id ).fetch()
      if selected_group == 'all' || selected_group of post.tags
        posts.push(post._id)
    
    #If the currently showing post is not in this group, show one that is
    if posts.length > 0 and not (Session.get("reply_#{@parent_id}") in posts)
      Session.set("reply_#{@parent_id}", posts[0])
    
    return posts
  
  reply: ->
    reply = Session.get("reply_#{@_id}")
    if reply?
      post = Posts.findOne( _id: reply )
    else
      post = Posts.findOne( parent_id: @_id )
    
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
  }
)
