Meteor.methods(
  get_user_id: ->
    if Meteor.accounts?
      #console.log 'meteor method (accounts present) get_user_id: ', @userId()
      return @userId()
    else
      #if auth packages do not exist, return the first id you can find.
      #console.log 'meteor method get_user_id: getting one from Users.findOne()'
      return Users.findOne({})._id
  
  get_post_by_id: (post_id) ->
    return Posts.findOne(post_id)
 
)
