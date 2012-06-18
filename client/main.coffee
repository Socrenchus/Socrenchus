# Collections
Users = new Meteor.Collection("users")
Posts = new Meteor.Collection("posts")

# Subscriptions
Meteor.subscribe( "my_posts" )
Meteor.subscribe( "assigned_posts" )
Meteor.autosubscribe ->
  Meteor.subscribe( "my_user" )
  
isLoggedIn = ->
  return true

_.extend( Template.sessionBar,
  user_id: ->
    return  Users.findOne({}).fetch()._id
)
  
_.extend( Template.posts,
  posts: ->
   if isLoggedIn()
      return Posts.find( 'parent_id': undefined )
  new: true
)

#Philip's Post Stuff
_.extend( Template.post,
  content: -> @content
  children: -> Posts.find( parent_id: @_id )
  identifier: -> @_id
  #unfinished, trying to do an event.  
  events: {
    "click button[name='replySubmit']:first": ->
      console.log("ID of Post you're replying to: #{ @_id }")
      replyContent = document.getElementById("replyText-#{ @_id }").value #Bryan thinks there's a way to do this without traversing the DOM.
      #debug
      console.log(replyContent)
      #dbase management
      console.log("ID of new post: "
        Posts.insert(
          {
            content: replyContent,
            parent_id: @_id
            instance_id: @instance_id
            author_id: true##
            
          }
        )
      )
      ###
      console.log(
        Posts.insert(
            {
              content: '<should be contents of reply box>',#TODO: Make this happen.
              parent_id: @_id
              #TODO: author_id, instance_id, empty tags...
            }
          )
      )
      ###
      #console.log(@_id)
      #stopPropogation()
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
      user_id: isLoggedIn()._id
    unless Tags.findOne( t )
      Tags.insert( t )

Router = new Router()
Meteor.startup ->
  Backbone.history.start( pushState: true )