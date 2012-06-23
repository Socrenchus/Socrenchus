# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users_proto")

# Subscriptions
Meteor.subscribe( "my_user" )
Meteor.subscribe( "my_posts" )
Meteor.subscribe( "assigned_posts" )

# Get User ID
Meteor.call('get_user_id', (err, res) ->
  Session.set('user_id', res)
)

# Backbone router
class Router extends Backbone.Router
  routes:
    ":post_id": "show_post"
    "new" : "new"

  show_post: (post_id) ->
    Meteor.call('get_post_by_id', post_id, (error, result) ->
      Session.set('showing_post', result)
      console.log(Session.get('showing_post'))
    )

Router = new Router()
Meteor.startup( ->
  Backbone.history.start( pushState: true ) #!SUPPRESS no_headless_camel_case
)