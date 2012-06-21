_.extend( Template.stream,
  group_posts: -> 
    MIN_POSTS = 2
    count = Posts.find( 'parent_id': @_id ).count()
    return count >= MIN_POSTS
  posts: ->
    return Posts.find( 'parent_id': @_id )
  groups: ->
    groups = {}
    for post in Posts.find( 'parent_id': @_id ).fetch()
      tags = (key for key of post.tags)
      tags = ['incubator'] unless tags.length
      for tag in tags
        unless tag of groups
          groups[tag] = []
        groups[tag].push post
    return ({name:k,posts:v} for k,v of groups)
  new: true
)
