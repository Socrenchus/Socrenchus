Meteor.methods(
  user_id: -> @userId()
  get_post_by_id: (post_id) ->
    p = Posts.findOne(post_id)
    return new ClientPost( p, @userId() ) if p?
  reset_notifications: ->
    Meteor.users.update( @userId(), { '$set': { notify: new Date() } } )
    
)
