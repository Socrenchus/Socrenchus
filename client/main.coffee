# Collections
Users = new Meteor.Collection("users")
Posts = new Meteor.Collection("posts")

# Session Variables
Session.set('user_id', 'someuserid')

# Subscriptions
Meteor.subscribe( "my_posts" )
Meteor.subscribe( "assigned_posts" )
Meteor.autosubscribe ->
  Meteor.subscribe( "my_user", Session.get( 'user_id' ) )

#Template variables/functions
min_posts = 0

graduated = (tag) ->
  return true

makeGroups = (posts) ->
  groups = [{'name': "Incubator", 'posts': []}]
  for post in posts.fetch()
    count = 0
    `for(tag in post.tags){
      if (graduated(tag)) {
        var tagGroup = [];
        if (tagGroup.length == 0) {
          groups.push({name: tag, posts: [post]});
        } else {
          groups[0].posts.push(post);
        }
      } else {
        groups[0].posts.push(post);
      }
      count++;
    }`
    if count == 0
      groups[0].posts.push(post)
      groups[0].name = "Incubator"
  return groups
  
getNtfs = ->
  return [{message: 'hi'},{message: 'there'}]

#Template extensions
_.extend( Template.body,
  events: {
    'click': (event) ->
      if !(event.isPropagationStopped()) && Session.equals("state", 'open')
        Session.set("state", 'closed')
  }
)

_.extend( Template.stream,
  posts: ->
    user_id = Session.get('user_id')
    if user_id
      return Posts.find( 'parent_id': undefined )
  new: true
)

_.extend( Template.post,
  content: -> @content
  groups: -> 
    children = Posts.find( parent_id: @_id )
    numChildren = children.count()
    if numChildren == 0
      return []
    else if numChildren < min_posts
      return [{name: "inc.", posts: children}]
    else
      return makeGroups(children)
)

_.extend( Template.group,
  name: -> @name
  posts: -> @posts
)

_.extend( Template.notifications,
  count: -> getNtfs().length
  ntfs: getNtfs
  show: -> Session.equals("state",'open')
  events: {
    'click #notification-counter': (event) ->
      if Session.equals("state", 'open')
        Session.set("state", 'closed')
      else
        Session.set("state", 'open')
    'click': (event) ->
      event.stopPropagation()
  }
)

_.extend( Template.notification,
  message: -> @message
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

