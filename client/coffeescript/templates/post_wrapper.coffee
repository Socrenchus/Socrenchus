_.extend( Template.post_wrapper,

  group_class: ->
    #alert(@cur)
    #alert(Session.get("group_#{@parent_id}"))
    if Session.get("group_#{@parent_id}") is @cur
      return ' selected'
  reply_class: ->
    if Session.get("reply_#{@parent_id}") is @cur
      return ' selected'

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
    
    #If the currently showing post is not in this group, show one that is
    if posts.length > 0 and not (Session.get("reply_#{@parent_id}") in posts)
      Session.set("reply_#{@parent_id}", posts[0])
    
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
    #Need to safify this.
    ###
    if this_post.author?.emails?.length>0
      return this_post.author.emails[0].md5()
    else
      return this_post.author._id.md5()
    ###
    return "NOOOOOOO"
      
  reply: ->
    reply = Session.get("reply_#{@_id}")
    if reply?
      post = Posts.findOne( _id: reply )
    else
      post = Posts.findOne( parent_id: @_id )
    
    return {exists: post?, post: post}
  
  events: {
    "click button.group": (event) ->
      if not event.isPropagationStopped()
        Session.set("group_#{@parent_id}", event.target.getAttribute('name'))
        event.stopPropagation()
    
    "click button.post": (event) ->
      if not event.isPropagationStopped()
        elem = event.target
        while(elem.nodeName.toLowerCase() isnt 'button')
          elem = elem.parentNode #bubble up
        Session.set("reply_#{@parent_id}", elem.getAttribute('name'))
        event.stopPropagation()
          
  }
)
