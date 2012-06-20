_.extend( Template.group,
  name: -> @name
  posts: -> {'post':post, 'group':@name} for post in @posts
)