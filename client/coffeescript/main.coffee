# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users")

# Subscriptions
Meteor.subscribe( "my_user", 0 )
Meteor.subscribe( "my_posts" )
Meteor.subscribe( "assigned_posts" )

# Temporary user info
console.log(Users.findOne())
Session.set('user_id', Users.findOne()._id)

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

