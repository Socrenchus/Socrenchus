@Users = Meteor.users
@Posts = new Meteor.Collection( "posts" )
@Instances = new Meteor.Collection( "instances" )
@Notifications = new Meteor.Collection("notifications")

watchPostsAndRespond = (mongoCursor) ->
  first_run = true
  
  action = (idx, type) =>
    doc = Posts.findOne(idx)
    client_post = new ClientPost( doc, @userId )
    @[type]("posts", client_post._id, client_post)
    unless first_run
      @ready()
  
  handle = mongoCursor.observeChanges(
    added: (idx) -> action(idx, 'added')
    changed: (idx) -> action(idx, 'changed')
  )
  
  @ready() if first_run
  first_run = false
  
  @onStop( =>
    handle.stop()
    mongoCursor.rewind()
    posts = mongoCursor.fetch()
    for post in posts
      fields = (key for key of ClientPost)
      @removed( "client_posts", post._id, fields )
    @ready()
  )
  

Meteor.publish("my_notifs", ->
  if @userId?
    return Notifications.find( user: @userId )
)

Meteor.publish("cover_posts", ->
  q = Posts.find({}, limit: 10)
  watchPostsAndRespond.call(@, q)
)

Meteor.publish("current_posts", (post_id) ->
  ids = [ post_id ]
  while ids[0]?
    p = Posts.findOne( ids[0] )
    if p.parent_id?
      ids.unshift( p.parent_id )
    else
      break
  
  in_ids = { '$in': ids }

  q = Posts.find( { '$or': [{_id:in_ids},{parent_id:in_ids}] } )
  watchPostsAndRespond.call(@, q)
)
