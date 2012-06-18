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

_.extend( Template.sessionBar,
  user_id: ->
    return Session.get('user_id')
)

_.extend( Template.posts,
  posts: ->
    user_id = Session.get('user_id')
    if user_id
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
            author_id: Session.get('user_id')
            
          }
        )
      )
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