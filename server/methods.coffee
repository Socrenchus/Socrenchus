Meteor.methods
  get_user_id: -> 
    if Meteor.accounts?
      return @userId()
      #if auth packages do not exist, return the first id you can find.
    else
      return Users.findOne({})._id
  
  get_post_by_id: (post_id) ->
    return Posts.findOne (post_id)
  
