# Collections
Users = new Meteor.Collection("users")
Posts = new Meteor.Collection("posts")

# Session Variables
###
Meteor.call('gimmeUserID', 
  (_error, _result) ->
    Session.set('user_id', _result)
    console.log(_result)
    console.log(_error)
)###
Session.set('user_id', 'some_user_id')

Meteor.subscribe( "my_posts")
Meteor.subscribe( "assigned_posts" )
# Subscriptions
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
      replyTextBox = document.getElementById("replyText-#{ @_id }")#Bryan thinks there's a way to do this without traversing the DOM.
      replyContent = replyTextBox.value
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
      #clear the textbox for giggles -- should probably do this only if the post succeeds.  
      replyTextBox.value = ''
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