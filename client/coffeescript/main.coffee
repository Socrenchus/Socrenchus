# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users")

# Subscriptions
Meteor.subscribe( "my_posts")
Meteor.subscribe( "assigned_posts" )

#Template variables/functions
min_posts = 1

#Graduated: Determines whether to group a post by a tag.  Would they make a good couple?  Have they earned each other?  
graduated = (tag, post) -> #The post/tag pair is graduated if the post is elegible to be grouped by that tag.
  return post.tags[tag].users.length >= 2 # 2 or more users have tagged it with that tag.  

###
#MakeGroups: Make a list of groups containing posts, for a given set of posts.
#    Incubator group
#    Tag group: group for each graduated tag.  
###
makeGroups = (posts) ->
  groups = {'Incubator': {'posts': []}}
  for post in posts.fetch()
    tagCount = 0
    placed = false #post has not been placed into a group yet.
    for tag of post.tags
      if graduated(tag, post) 
        if groups[tag]? #if there is a group for this tag
          groups[tag].posts.push(post) #add this post to the group's posts
        else
          groups[tag] = {'posts': [post]} #add a tag group with a "posts" field containing this post
        placed = true #this post has been placed
      else if not placed #if the post isn't graduated and hasn't 
        groups['Incubator'].posts.push(post)
        placed = true
      tagCount++
    if tagCount == 0
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
  group_name: -> ""
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
  identifier: -> @_id
  events: {
    "click button[name='replySubmit']": (event) ->
      
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
      event.stopImmediatePropagation()
  }
  
)

_.extend( Template.group,
  group_name: -> @name
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

