Users = Meteor.users
Posts = new Meteor.Collection( "posts" )
Instances = new Meteor.Collection( "instances" )
Notifications = new Meteor.Collection("notifications")


Meteor.publish("my_notifs", ->
  user_id = @userId()
  if user_id?
    return Notifications.find( user: user_id )
)

Meteor.publish("cover_posts", ->
  user_id = @userId()
  
  action = (doc, idx) =>
    client_post = new ClientPost( doc, user_id )
    @set("posts", client_post._id, client_post)
    unless first_run
      @flush()
  
  q = Posts.find()
  handle = q.observe(
    added: action
    changed: action
  )
  
  @flush() if first_run
  first_run = false
  
  @onStop( =>
    handle.stop()
    q.rewind()
    posts = q.fetch()
    for post in posts
      fields = (key for key of ClientPost)
      @unset( "cover_posts", post._id, fields )
    @flush()
  )
)

Meteor.publish("current_posts", (post_id) ->
  user_id = @userId()
  
  ids = [ post_id ]
  while ids[0]?
    p = Posts.findOne( ids[0] )
    if p.parent_id?
      ids.unshift( p.parent_id )
    else
      break
  
  action = (doc, idx) =>
    client_post = new ClientPost( doc, user_id )
    @set("posts", client_post._id, client_post)
    unless first_run
      @flush()
  
  in_ids = { '$in': ids }

  q = Posts.find( { '$or': [{_id:in_ids},{parent_id:in_ids}] } )
  handle = q.observe(
    added: action
    changed: action
  )
  
  @flush() if first_run
  first_run = false
  
  @onStop( =>
    handle.stop()
    q.rewind()
    posts = q.fetch()
    for post in posts
      fields = (key for key of ClientPost)
      @unset( "client_posts", post._id, fields )
    @flush()
  )
)
