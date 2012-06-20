# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users")

# Subscriptions
Meteor.subscribe( "my_posts")
Meteor.subscribe( "assigned_posts" )

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
    return Posts.find( 'parent_id': undefined )
  new: true
)

_.extend( Template.post,
  content: -> 
    showdownConverter = new Showdown.converter()
    postContentHtml = showdownConverter.makeHtml(@content)
    return postContentHtml
  groups: -> 
    children = Posts.find( parent_id: @_id )
    numChildren = children.count()
    if numChildren == 0
      return []
    else if numChildren < min_posts
      return [{name: "All Replies", posts: children}]
    else
      return makeGroups(children)
  identifier: -> 
    id = @_id
    if @group_name?
      id += @group_name
    return id
  
  ###
  <div class="your-reply" id="reply-cfa3e5db-97c9-4617-884b-d1e7f173a7ea">
        <textarea name="replyText" id="replyText-cfa3e5db-97c9-4617-884b-d1e7f173a7ea" cols="70" rows="7"></textarea>
        <button name="replySubmit" id="replySubmit-cfa3e5db-97c9-4617-884b-d1e7f173a7ea" type="button">Post Reply!</button>
        <!--<button name="replyCancel" id="replyCancel-cfa3e5db-97c9-4617-884b-d1e7f173a7ea" type="button">^</button>--><!--Hidden from Bryan-->
      </div>
  ###
  
  events: {
    "click button[name='replySubmit']": (event) ->
      event.stopPropagation()
      replyTextBox = document.getElementById("replyText-#{ @_id }")#Bryan thinks there's a way to do this without traversing the DOM.
      
      replyContent = replyTextBox.value
      console.log("ID of Post you're replying to: #{ @_id }")
      console.log("Reply content: #{replyContent}")
      console.log("ID of new post: "
        Posts.insert(
          {
            content: replyContent,
            parent_id: @_id,
            instance_id: @instance_id
          }
        )
      )
      replyTextBox.value = '' #clear the textbox for giggles -- should probably do this only if the post succeeds.
  }
  
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
    unless Tags.findOne( t )
      Tags.insert( t )

Router = new Router()
Meteor.startup ->
  Backbone.history.start( pushState: true )

