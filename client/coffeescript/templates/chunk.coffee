_.extend( Template.chunk,
  not_root: -> @parent_id?
  groups: ->
    #groups = ['all'] #Not needed, this is added in through html in another group.
    groups = []
    for post in Posts.find( 'parent_id': @parent_id ).fetch()
      tags = (tag for tag of post.tags)
      for tag in tags
        groups.push(tag) unless tag in groups
    return groups
  
  vis_posts: ->
    console.log(@parent_id)
    selected_group = Session.get("group_#{@parent_id}")
    unless selected_group?
      selected_group = 'all'
    posts = []
    for post in Posts.find( 'parent_id': @parent_id ).fetch()
      posts.push(post._id) if selected_group == 'all' || selected_group of post.tags
    return posts
  
  reply: ->
    reply = Session.get("reply_#{@parent_id}")
    if reply?
      return Posts.findOne( _id: reply )
    else
      return @
  
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
  
  ###
  groups: ->
    groups = {'all': []}
    for post in Posts.find( 'parent_id': @_id ).fetch()
      groups.all.push(post._id)
      tags = (tag for tag of post.tags)
      for tag in tags
        groups[tag] = [] unless tag of groups
        groups[tag].push(post._id)
    return [] if groups.all.length == 0
    return ({name:k,posts:v} for k,v of groups)
  ###
)
