# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users_proto")

# Subscriptions
Meteor.subscribe( "my_user" )
Meteor.subscribe( "my_posts" )
Meteor.subscribe( "assigned_posts" )

# Temporary user info
# TODO: change this to anup's upcoming Meteor method which gets the current user's id
Session.set('user_id', 999) #999 is a dummy value
console.log(Session.get('user_id'))

# Backbone router
class Router extends Backbone.Router
  routes:
    ":post_id": "assign"
    "new" : "new"

  assign: (post_id) ->
    t = 
      name: ',assignment'
      post_id: post_id
    unless Tags.findOne( t )
      Tags.insert( t )

Router = new Router()
Meteor.startup ->
  Backbone.history.start( pushState: true )

