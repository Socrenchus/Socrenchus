Meteor.methods(
  get_post_by_id: (post_id) ->
    return Posts.findOne(post_id)
 
)