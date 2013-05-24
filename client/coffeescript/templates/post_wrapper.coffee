_.extend( Template.post_wrapper,

  group_selected: ->
    s = Session.get("group_#{@parent_id}")
    s ?= 'all'
    return s is @cur.name.toString()
  
  selected_group: ->
    return Session.get("group_#{@parent_id}")
    
  title_current_group: ->
    if @cur.name? and @cur.name isnt 'all'
      return "Posts tagged as '#{@cur.name}'"
    else
      return "All Posts"
    
  title_selected_group: ->
    group = Session.get("group_#{@parent_id}")
    if group? and group isnt 'all'
      return "A post tagged as '#{group}'"
    else
      return "A post in the 'All' group"
  
  reply_class: ->
    if Session.get("reply_#{@parent_id}") is @cur.toString()
      return ''#selected
    else
      return ' btn-inverse faded-img'

  not_root: -> @parent_id?
  
  groups: ->
    groups = {}
    for post in Posts.find( 'parent_id': @parent_id ).fetch()
      tags = (tag for tag of post.tags)
      tags.push('all')
      for tag in tags
        unless tag of groups
          author = post?.author
          hash = get_primary_email(author).md5()
          obj =
            name: tag
            count: 1
            width: 0 #Width is (count-1) * 4
            hash: hash
          groups[tag] = obj
        else
          groups[tag].count++
          groups[tag].width += 4
    return ( v for k,v of groups )
  
  group_posts: ->
    selected_group = Session.get("group_#{@parent_id}")
    selected_group ?= 'all'
    posts = []
    actual_posts = []
    tag_order = {}
    tag_order["tags.#{selected_group}"] = -1
    for post in Posts.find( { 'parent_id': @parent_id }, {sort:tag_order} ).fetch()
      if selected_group == 'all' || selected_group of post.tags
        posts.push(post._id)
        actual_posts.push(post)
    
    #If the currently showing post is not in this group, show one that is
    if posts.length > 0 and not (Session.get("reply_#{@parent_id}") in posts)
      Session.set("reply_#{@parent_id}", posts[0])
      Session.set('showing_post', actual_posts[0])
    
    return posts
  
  author_email: ->
    this_post = Posts.findOne( _id: @cur )
    author = this_post.author
    if author? and author.emails? and author.emails.length? and author.emails.length>0
      return author.emails[0]
    
  email_hash: ->
    this_post = Posts.findOne( _id: @cur )
    author = this_post.author
    return get_primary_email(author).md5()
      
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
    "mousedown button.group": (event) ->
      if not event.isPropagationStopped()
        elem = event.target
        while(elem.nodeName.toLowerCase() isnt 'button')
          elem = elem.parentNode #bubble up
        Session.set("group_#{@parent_id}", elem.getAttribute('name'))
        
        event.stopPropagation()
    
    "mousedown button.post": (event) ->
      if not event.isPropagationStopped()
        elem = event.target
        while(elem.nodeName.toLowerCase() isnt 'button')
          elem = elem.parentNode #bubble up  
        Session.set('showing_post', Posts.findOne( elem.getAttribute('name') ))
        Session.set("reply_#{@parent_id}", elem.getAttribute('name'))
        event.target.click?()
        event.stopPropagation()
    
    'click': (event) ->
      if Session.get('showing_post')._id is @parent_id
        Session.set('showing_post', @)
  }
)
