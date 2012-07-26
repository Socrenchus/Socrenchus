# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users_proto")

# Subscriptions
Meteor.subscribe( "my_posts" )
Meteor.subscribe( "assigned_posts" )

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

get_timestamp = (original) ->
  timestamp = new Date(original.timestamp)
  
  #Get smart timestamp
  timediff = (new Date()).getTime() - timestamp.getTime()
  if timediff < (1000*60) #under one minute ago
    smart = "#{Math.round(timediff / 1000)} seconds ago"
  else if timediff < (1000*60*60) #under one hour ago
    smart = "#{Math.round(timediff / 1000 / 60)} minutes ago"
  else if timediff < (1000*60*60*24) #under one day ago
    smart = "#{Math.round(timediff / 1000 / 60 / 60)} hours ago"
  else if timediff < (1000*60*60*24*7) #under one week ago
    days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    smart = "on #{days[timestamp.getDay()]}"
  else
    smart = timestamp.toDateString()
  
  #Get full timestamp
  ap = 'am'
  hour = timestamp.getHours()
  ap = 'pm' if hour > 11
  hour = hour - 12 if hour > 12
  hour = 12 if hour == 0
  minutes = timestamp.getMinutes()
  minutes = "0#{minutes}" if minutes < 10
  full = "#{timestamp.toDateString()} at #{hour}:#{minutes}#{ap}"
  return {smart: smart, full: full}
