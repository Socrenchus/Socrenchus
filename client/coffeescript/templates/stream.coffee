Session.set('streams', {})
Session.set('test', {})

_.extend( Template.stream,
  all_replies: ->
    return Posts.find( 'parent_id': @_id ).fetch()
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

  posts: ->
    a = Session.get('test')[@id]
    console.log(@id)
    return a

  events: {
    "click button[name='individual_post']": (event) ->
      if not event.isPropagationStopped()
        Router.navigate("#{@_id}", { trigger: true })
        event.stopPropagation()
    
    "click button[name='group']": (event) ->
      if not event.isPropagationStopped()
        test = Session.get('streams')
        test[@id] ?= {}
        test[@id][replies] = @posts
        Session.set('streams', _.clone(test))
        event.stopPropagation()
  }
)
