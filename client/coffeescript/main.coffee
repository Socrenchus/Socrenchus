# Collections
@Posts = new Meteor.Collection("posts")
@Notifications = new Meteor.Collection("notifications")

# Subscriptions
Meteor.subscribe( "my_notifs" )
# Meteor.subscribe( "cover_posts" )

# Backbone router
class Router extends Backbone.Router
  routes:
    "": "home"
    "i/*args": "use_instance"
    "p/:post_id": "show_post"
   
  home: ->
    Session.set('showing_post', undefined)
    Session.set('home', true)

  show_post: (post_id) ->
    Meteor.call('get_post_by_id', post_id, (error, result) ->
      Session.set('showing_post', result)
    )
    Meteor.autosubscribe( ->
      Meteor.subscribe( "current_posts", Session.get('showing_post')?._id )
    )
    #history.replaceState(null,'Socrenchus','/')

  use_instance: (args) ->
    args = args.split( '/' )
    domain = args[0]
    window.instance = domain
    other = args[1..].join( '/' )
    l = $( "<link/>" )
    l.attr( 'type', 'text/css' )
    l.attr( 'rel', 'stylesheet' )
    l.attr( 'href', "//#{domain}/style.css" )
    $('head').append( l )
    Backbone.history.options.root = "/i/#{domain}/"
    if other?
      Backbone.history.navigate("/#{other}", trigger: true)
  
  link: (url) ->
    unless window.instance?
      return "#{window.location.host}#{url}"
    return "#{window.instance}#{url}"

Router = new Router()
Meteor.startup( ->
  # Get User ID
  Session.set('user_id', @userId)
  
  Backbone.history.start( pushState: true ) #!SUPPRESS no_headless_camel_case
)

get_primary_email = (author) ->
  if author?
    if author.emails? and author.emails.length? and author.emails.length>0
      author = author.emails[0]
    else if author._id?
      author = author._id
  else
    author = "NO AUTHOR"
  switch typeof author
    when 'string' then return author
    when 'object' then return author.email

# Handlebars helper, an extension of 'with'.  'with' completely replaces the
#   current context with the previous context, while 'both' keeps the current
#   context as an additional field.
Handlebars.registerHelper('both', (context, options) ->
  return options.fn(_.extend(context ? {}, {cur:@}))
)

#http://thinkvitamin.com/code/handlebars-js-part-3-tips-and-tricks/
Handlebars.registerHelper('debug', (optionalValue) ->
  console.log "Current Context"
  console.log "===================="
  console.log this
  if optionalValue
    console.log "Value"
    console.log "===================="
    console.log optionalValue
)
