# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users_proto")
Instances = new Meteor.Collection("instances")

# Subscriptions
Meteor.subscribe( "my_posts" )
Meteor.subscribe( "assigned_posts" )
Meteor.subscribe( 'instance', window.location.host )

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
  # Get User ID
  Meteor.call('get_user_id', (err, res) ->
    Session.set('user_id', res)
  )

  Backbone.history.start( pushState: true ) #!SUPPRESS no_headless_camel_case
  
)

# Handlebars helper, an extension of 'with'.  'with' completely replaces the
#   current context with the previous context, while 'both' keeps the current
#   context as an additional field.
Handlebars.registerHelper('both', (context, options) ->
  return options.fn(_.extend(context ? {}, {cur:@}))
)
