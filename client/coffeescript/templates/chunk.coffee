_.extend( Template.chunk,
  init: ->
    console.log('fuck meteor')
    Session.set("reply_group_#{@parent_id}", {group: null, reply: @_id})
  not_root: -> @parent_id?
  groups: ->
    groups = ['all']
    for post in Posts.find( 'parent_id': @parent_id ).fetch()
      tags = (tag for tag of post.tags)
      for tag in tags
        groups.push(tag) unless tag in groups
    return groups
  
  vis_posts: ->
    selected_group = Session.get("reply_group_#{@parent_id}")
    if selected_group?
      
    else
      return Posts.find( 'parent_id': @parent_id ).fetch()
  
  reply: ->
    Posts.find( _id: Session.get("reply_group_#{@parent_id}").reply )
  
  events: {
    "click button[name='group']": (event) ->
      if not event.isPropagationStopped()
        Session.set("reply_group_#{@parent_id}", {group: event.target.className} )
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
