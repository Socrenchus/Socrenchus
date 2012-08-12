Meteor.methods(
  get_post_by_id: (post_id) ->
    p = Posts.findOne(post_id)
    return new ClientPost( p ) if p?
 
)
