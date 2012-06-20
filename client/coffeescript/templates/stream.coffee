_.extend( Template.stream,
  posts: ->
    return (Posts.find( 'parent_id': undefined ).map (post) -> {'post':post, 'group':""})
  new: true
)