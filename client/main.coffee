# Collections
Posts = new Meteor.Collection("posts")
Users = new Meteor.Collection("users")

# Subscriptions
Meteor.subscribe( "my_posts")
Meteor.subscribe( "assigned_posts" )

_.extend( Template.sessionBar,
  username: ->
    return "USERNAME"
)

_.extend( Template.posts,
  posts: ->
    return Posts.find( 'parent_id': undefined )
  new: true
)

#Philip's Post Stuff
_.extend( Template.post,
  content: -> 
    showdownConverter = new Showdown.converter()
    postContentHtml = showdownConverter.makeHtml(@content)
    return postContentHtml
  children: -> Posts.find( parent_id: @_id )
  identifier: -> @_id
  events: {
    "click button[name='replySubmit']:first": ->
      replyTextBox = document.getElementById("replyText-#{ @_id }")#Bryan thinks there's a way to do this without traversing the DOM.
      replyContent = replyTextBox.value
      console.log("ID of Post you're replying to: #{ @_id }")
      console.log("Reply content: #{replyContent}")
      console.log("ID of new post: "
        Posts.insert(
          {
            content: replyContent,
            parent_id: @_id
            instance_id: @instance_id
          }
        )
      )
      replyTextBox.value = '' #clear the textbox for giggles -- should probably do this only if the post succeeds.  
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