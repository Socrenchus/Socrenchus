_.extend( Template.post_wrapper,

  allbutton_class: ->
    if not Session.get("group_#{@parent_id}")?
      return ' btn-inverse'
  group_class: ->
    if Session.get("group_#{@parent_id}") is @cur.toString()
      return ' btn-inverse'
  reply_class: ->
    if Session.get("reply_#{@parent_id}") is @cur.toString()
      return ' btn-inverse'#selected

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
    this_post = Posts.findOne( _id: @cur )
    author = this_post.author
    if author? and author.emails? and author.emails.length? and author.emails.length>0
      return author.emails[0]
    
  email_hash: ->
    this_post = Posts.findOne( _id: @cur )
    author = this_post.author
    if author?
      if author.emails? and author.emails.length? and author.emails.length>0
        return author.emails[0].md5()
      else if author._id?
        return author._id.md5()
    else
      return "NO AUTHOR".md5()
    
    #When the db is ready...
    #this_post = Posts.findOne( _id: @cur )
    #return Users.findOne( _id: this_post.author_id ).email.md5()
    
    #Need to safify this.
    ###
    if this_post.author?.emails?.length>0
      return this_post.author.emails[0].md5()
    else
      return this_post.author._id.md5()
    ###
      
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
    "mousedown button.allbutton": (event) ->
      if not event.isPropagationStopped()
        Session.set("group_#{@parent_id}", null)
        event.stopPropagation()
    
    "mousedown button.group": (event) ->
      if not event.isPropagationStopped()
        Session.set("group_#{@parent_id}", event.target.getAttribute('name'))
        event.stopPropagation()
    
    "mousedown button.post": (event) ->
      if not event.isPropagationStopped()
        elem = event.target
        while(elem.nodeName.toLowerCase() isnt 'button')
          elem = elem.parentNode #bubble up
        Session.set("reply_#{@parent_id}", elem.getAttribute('name'))
        event.stopPropagation()
    
    'click': (event) ->
      parent = Session.get('carousel_parent')
      ancestors = [(cur = @).parent_id]
      while cur?.parent_id?
        cur = Posts.findOne( _id: cur.parent_id )
        ancestors.push(cur.parent_id)
      if parent._id in ancestors && not Session.equals('carousel_handle',null)
        Meteor.clearInterval(Session.get('carousel_handle'))
        Template.post_wrapper.start_carousel(@)
  }
  
  start_carousel: (parent_post) ->
    Session.set('carousel_parent', parent_post)
    carousel_handle = Meteor.setInterval( ->
      parent = Session.get('carousel_parent')
      cur_reply = Session.get("reply_#{parent._id}")
      if parent? and cur_reply?
        all_replies = Posts.find( parent_id: parent._id ).fetch()
        idx = 0
        for reply, i in all_replies
          if reply._id is cur_reply
            idx = (i + 1) % all_replies.length
        Session.set("reply_#{parent._id}", all_replies[idx]._id)
    , 3000)
    Session.set('carousel_handle', carousel_handle)
)
