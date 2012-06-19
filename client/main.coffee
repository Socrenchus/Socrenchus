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

graduated = (tag, post) ->
  return post.tags[tag].users.length >= 2

makeGroups = (posts) ->
  groups = {'Incubator': {'posts': []}}
  for post in posts.fetch()
    count = 0
    placed = 0
    for tag,info of post.tags
      if graduated(tag, post)
        if groups[tag]?
          groups[tag].posts.push(post)
        else
          groups[tag] = {'posts': [post]}
        placed++
      else if placed == 0
        groups['Incubator'].posts.push(post)
        placed++
      count++
    if count == 0
      groups['Incubator'].posts.push(post)
  groupList = []
  for name,info of groups
    if info.posts.length != 0
      groupList.push({'name':name, 'posts':info.posts})
  return groupList
  
tempNotfs = [{message: 'hi'},{message: 'there'},
      {message: 'friend'},{message: 'how'},
      {message: 'are'},{message: 'you'},
      {message: 'today'}]
      
Session.set("notfs", tempNotfs)

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
      return [{name: "All Replies", posts: children}]
    else
      return makeGroups(children)
)

_.extend( Template.group,
  name: -> @name
  posts: -> @posts
)

_.extend( Template.notifications,
  count: -> Session.get("notfs").length
  ntfs: -> return Session.get("notfs")
  show: -> Session.equals("state",'open')
  message: -> @message
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

