Meteor.methods(
  user_id: -> @userId
  get_post_by_id: (post_id) ->
    p = Posts.findOne(post_id)
    return new ClientPost( p, @userId ) if p?
  reset_notifications: ->
    Notifications.update( { 'user': @userId, 'seen': false }, '$set': { 'seen': true } )
  read_notification: (notification_id) ->
    Notifications.update( notification_id, '$set': { read: true } )
)
