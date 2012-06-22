Meteor.methods
  userId: -> 
    if Meteor.accounts?
      return @userId()
    else
      return Users.findOne({})._id

  get_post_by_id: (post_id) ->
    return Posts.findOne(post_id)
    