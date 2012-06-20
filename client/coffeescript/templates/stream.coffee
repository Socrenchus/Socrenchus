_.extend( Template.stream,
  posts: ->
    return Posts.find( 'parent_id': undefined )
  new: true
)
