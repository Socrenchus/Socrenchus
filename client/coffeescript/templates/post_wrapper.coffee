_.extend( Template.post_wrapper,
  not_root: -> @parent_id?
  groups: ->
    #groups = ['all']
    groups = []
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
    return posts
  
  author_email: ->
    #When the db is ready...
    #this_post = Posts.findOne( _id: @cur )
    #return Users.findOne( _id: this_post.author_id ).email
    
    #this_post = Posts.findOne( _id: @cur )
    #return this_post.author_id
    
    return "@"
    
  email_hash: ->
    #When the db is ready...
    #this_post = Posts.findOne( _id: @cur )
    #return Users.findOne( _id: this_post.author_id ).email.md5()
    this_post = Posts.findOne( _id: @cur )
    return this_post.author_id.md5()
  
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
        elem = event.target
        while(elem.nodeName.toLowerCase() isnt 'button')
          elem = elem.parentNode #bubble up
        Session.set("reply_#{@parent_id}", elem.className)
        event.stopPropagation()
          
  }
)
