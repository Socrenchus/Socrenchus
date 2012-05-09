# Collections
Users = new Meteor.Collection("users")
Posts = new Meteor.Collection("posts")
Tags = new Meteor.Collection("tags")

# Session Variables
Session.set "user_id", null

# Subscriptions
Meteor.subscribe( "my_posts" )

_.extend( Template.posts,
  posts: ->
    q = Posts.find().fetch()
    ids = (r._id for r in q)
    result = []
    for x in q
      result.unshift x unless (x.parent_id in ids)
    return result
  new: true
)

_.extend( Template.post,
  content: -> @content
  children: -> Posts.find( parent_id: @_id )
)

# Backbone router
class Router extends Backbone.Router
  routes:
    ":post_id": "assign"
    "new" : "new"

  assign: (post_id) ->
    t = 
      name: ',assignment'
      post_id: post_id
      user_id: Session.get( 'user_id' )
    unless Tags.findOne( t )
      Tags.insert( t )

Router = new Router()
Meteor.startup ->
  Backbone.history.start( pushState: true )
  $('#omnipost').omnipost()