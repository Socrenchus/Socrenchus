@Users = Meteor.users
@Posts = new Meteor.Collection( "posts" )
@Instances = new Meteor.Collection( "instances" )
@Notifications = new Meteor.Collection("notifications")


Meteor.publish("my_notifs", ->
  user_id = @userId
  if user_id?
    return Notifications.find( user: user_id )
)

Meteor.publish("cover_posts", ->
  first_run = true
  user_id = @userId
  
  action = (doc, idx) =>
    client_post = new ClientPost( doc, user_id )
    @changed("posts", client_post._id, client_post)
    unless first_run
      @ready()
  
  q = Posts.find()
  handle = q.observeChanges(
    added: action
    changed: action
  )
  
  @ready() if first_run
  first_run = false
  
  @onStop( =>
    handle.stop()
    q.rewind()
    posts = q.fetch()
    for post in posts
      fields = (key for key of ClientPost)
      @removed( "cover_posts", post._id, fields )
    @ready()
  )
)

Meteor.publish("current_posts", (post_id) ->
  first_run = true
  user_id = @userId
  
  ids = [ post_id ]
  while ids[0]?
    p = Posts.findOne( ids[0] )
    if p.parent_id?
      ids.unshift( p.parent_id )
    else
      break
  
  action = (doc, idx) =>
    client_post = new ClientPost( doc, user_id )
    @changed("posts", client_post._id, client_post)
    unless first_run
      @ready()
  
  in_ids = { '$in': ids }

  q = Posts.find( { '$or': [{_id:in_ids},{parent_id:in_ids}] } )
  handle = q.observeChanges(
    added: action
    changed: action
  )
  
  @ready() if first_run
  first_run = false
  
  @onStop( =>
    handle.stop()
    q.rewind()
    posts = q.fetch()
    for post in posts
      fields = (key for key of ClientPost)
      @removed( "client_posts", post._id, fields )
    @ready()
  )
)
