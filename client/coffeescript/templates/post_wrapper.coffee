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
          hash = null
          if author?
            if author.emails? and author.emails.length? and author.emails.length>0
              hash = author.emails[0].md5()
            else if author._id?
              hash = author._id.md5()
          hash ?= "NO AUTHOR".md5()
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
        elem = event.target
        Session.set("group_#{@parent_id}", null)
        event.stopPropagation()
    
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
        Session.set("reply_#{@parent_id}", elem.getAttribute('name'))
        event.target.click?()
        event.stopPropagation()
    
    'click': (event) ->
      parent = Session.get('carousel_parent')
      ancestors = [(cur = @).parent_id]
      while cur?.parent_id?
        cur = Posts.findOne( _id: cur.parent_id )
        ancestors.push(cur.parent_id)
      if parent._id in ancestors && window.carousel_handle?
        Template.post_wrapper.start_carousel(@)
  }
  
  start_carousel: (parent_post) ->
    Session.set('carousel_parent', parent_post)
    Meteor.clearInterval(window.carousel_handle)
    window.carousel_handle = Meteor.setInterval( ->
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
)
