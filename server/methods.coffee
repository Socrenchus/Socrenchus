Meteor.methods(
  get_post_by_id: (post_id) ->
    return new ClientPost( Posts.findOne(post_id) )
 
)
