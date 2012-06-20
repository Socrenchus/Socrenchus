# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users")

# Subscriptions
Meteor.subscribe( "my_posts")
Meteor.subscribe( "assigned_posts" )

#Template variables/functions
min_posts = 999

graduated = (tag, post) ->
  return post.tags[tag].users.length >= 2

addGroupName = (post, name) ->
  post['group_name'] = name

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
_.extend( Template.sessionBar,
  username: ->
    return "USERNAME"
)

_.extend( Template.body,
  events: {
    'click': (event) ->
      if !(event.isPropagationStopped()) && Session.equals("state", 'open')
        Session.set("state", 'closed')
  }
)

_.extend( Template.stream,
  posts: ->
    return (Posts.find( 'parent_id': undefined ).map (post) -> {'post':post, 'group':""})
  new: true
)

_.extend( Template.post,
  content: -> 
    showdownConverter = new Showdown.converter()
    postContentHtml = showdownConverter.makeHtml(@post.content)
    return postContentHtml
  groups: -> 
    children = Posts.find( parent_id: @post._id )
    numChildren = children.count()
    if numChildren == 0
      return []
    else if numChildren < min_posts
      return [{'name': "All Replies", 'posts': children.fetch()}]
    else
      return makeGroups(children)
  identifier: -> @post._id
  groupname: -> @group
  events: {
    "click button[name='replySubmit']": (event) ->
      if !event.isImmediatePropagationStopped()
        replyTextBox = document.getElementById("replyText-#{ @post._id }-#{ @group }")#Bryan thinks there's a way to do this without traversing the DOM.
        event.stopImmediatePropagation()
        replyContent = replyTextBox.value
        console.log("ID of Post you're replying to: #{ @post._id }-#{ @group }")
        console.log("Reply content: #{replyContent}")
        replyID = Posts.insert(
          {
            content: replyContent,
            parent_id: @post._id,
            instance_id: @post.instance_id
          }
        )
        console.log("ID of new post: "+replyID)
        replyTextBox.value = '' #clear the textbox for giggles -- should probably do this only if the post succeeds.
  }
  
)

_.extend( Template.group,
  name: -> @name
  posts: -> {'post':post, 'group':@name} for post in @posts
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
    unless Tags.findOne( t )
      Tags.insert( t )

Router = new Router()
Meteor.startup ->
  Backbone.history.start( pushState: true )

