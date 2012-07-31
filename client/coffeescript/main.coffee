# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users_proto")
Instances = new Meteor.Collection("instances")

# Subscriptions
Meteor.subscribe( "my_posts" )
Meteor.subscribe( "assigned_posts" )
Meteor.subscribe( 'instances' )

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
  #below needs to stay on client (unless we use HTTP GET, i think)
  current_url = window.location.host
  main_urls = ['socrenchus.com','socrench.us']
  is_main = current_url in main_urls
  #determine whether to display existing instance or tutorial for new one
  instance = Session.get('instance_id')
  if instance?
    tron.log('Displaying style for instance ', instance)
  else if not is_main
    Meteor.call('create_instance', current_url, Session.get('user_id'))
    # display loading screen - new url detected, alert the user
    #confirm dns and check email domain

  
  Backbone.history.start( pushState: true ) #!SUPPRESS no_headless_camel_case
)
