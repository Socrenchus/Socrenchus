# Collections
Users = new Meteor.Collection("users")
Posts = new Meteor.Collection("posts")
Tags = new Meteor.Collection("tags")

# Session Variables
Session.set "user_id", "9124fcdb-52fb-4a72-a31c-feec607d0847"

# Subscriptions
Meteor.subscribe( "my_posts" )
Meteor.subscribe( "my_tags" )
Meteor.autosubscribe ->
  Meteor.subscribe( "my_user", Session.get( 'user_id' ) )

_.extend( Template.posts,
  posts: ->
    user_id = Session.get( 'user_id' )
    if user_id
      tags = Tags.find( user_id: user_id, name: ',assignment' ).fetch()
      q = Posts.find( _id: {'$in':( t.post_id for t in tags )} ).fetch()
      ids = ( r._id for r in q )
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