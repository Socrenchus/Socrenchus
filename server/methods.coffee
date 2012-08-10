Meteor.methods(
  get_user_id: ->
    if Meteor.accounts?
      return @userId()
    else
      #if auth packages do not exist, return the first id you can find.
      return Users.findOne({})._id
  
  get_post_by_id: (post_id) ->
    return Posts.findOne(post_id)

  get_reply_count: (parent_id) ->
    i = 0
    i = Posts.find({parent_id: parent_id}).count()
    return i
)
