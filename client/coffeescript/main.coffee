# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users_proto")
Instances = new Meteor.Collection("instances")

# Subscriptions
Meteor.subscribe( "my_posts" )
Meteor.subscribe( "assigned_posts" )

# Backbone router
class Router extends Backbone.Router
  routes:
    "i/*args": "use_instance"
    "p/:post_id": "show_post"

  show_post: (post_id) ->
    Meteor.call('get_post_by_id', post_id, (error, result) ->
      Session.set('showing_post', result)
      console.log(Session.get('showing_post'))
    )

  use_instance: (args) ->
    args = args.split( '/' )
    domain = args[0]
    window.instance = domain
    other = args[1..].join( '/' )
    Meteor.subscribe( 'instance', domain )
    l = $( "<link/>" )
    l.attr( 'type', 'text/css' )
    l.attr( 'rel', 'stylesheet' )
    l.attr( 'href', "//#{domain}/style.css" )
    $('head').append( l )
    if other?
      Backbone.history.navigate("/#{other}", trigger: true)
      @navigate("/i/#{domain}/#{other}")

  link: (url) ->
    unless window.instance?
      return url
    return "/i/#{window.instance}#{url}"

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
