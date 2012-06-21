_.extend( Template.group,
  name: -> @name
  posts: ->
    unless @name == 'incubator'
      return @posts
    else
      return [@posts[0]]
)
