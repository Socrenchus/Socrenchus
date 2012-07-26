Session.set('streams', {})

_.extend( Template.stream,

  replies: ->
    reply = Posts.findOne('_id': Session.get('streams')[@_id]?.reply)
    group = Session.get('streams')[@_id]?.group
    replies = Session.get('streams')[@_id]?.replies
    return {group_chosen: group?, group: group, reply_chosen: reply?, reply: reply, replies: replies}
  
  is_selected_group: ->
    test = Session.get('streams')
    test[@id] ?= {}
    group = test[@id]?.group
    unless group?
      console.log(@name)
      test[@id]['group'] = @name
      Session.set('streams', _.clone(test))
    return group? && @name == group
  
  is_selected_post: ->
    reply = Session.get('streams')[@_id]?.reply
    return reply? && @cur.toString() == reply
  
  groups: ->
    groups = {'all': []}
    for post in Posts.find( 'parent_id': @_id ).fetch()
      groups.all.push(post._id)
      tags = (tag for tag of post.tags)
      for tag in tags
        groups[tag] = [] unless tag of groups
        groups[tag].push(post._id)
    return [] if groups.all.length == 0
    return ({name:k,posts:v,id:@_id} for k,v of groups)
  
  events: {
    "click button[name='individual_post']": (event) ->
      if not event.isPropagationStopped()
        replies = Session.get('streams')
        replies[@_id] ?= {}
        replies[@_id].reply = event.target.className
        Session.set('streams', _.clone(replies))
        event.stopPropagation()
    
    "click button[name='group']": (event) ->
      if not event.isPropagationStopped()
        replies = Session.get('streams')
        replies[@id] ?= {}
        replies[@id].group = event.target.className
        replies[@id].replies = @posts
        replies[@id].reply = undefined
        Session.set('streams', _.clone(replies))
        event.stopPropagation()
  }
)

doop = -> console.log('DOOP')
