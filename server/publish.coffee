Users = Meteor.users
Posts = new Meteor.Collection( "posts" )
Instances = new Meteor.Collection( "instances" )
Notifications = new Meteor.Collection("notifications")


Meteor.publish("my_notifs", ->
  user_id = @userId()
  if user_id?
    return Notifications.find( user: user_id )
)

Meteor.publish("current_posts", (post_id) ->
  user_id = @userId()
  
  ids = [ post_id ]
  ids.unshift( Posts.findOne( ids[0] ).parent_id ) while ids[0]?
  ids = ids[1..]
  
  first_run = true
  visible = {}
  visible[ post_id ] = true
  saved = {}
  
  send = ( doc ) =>
    client_post = new ClientPost( doc, user_id )
    @set("posts", client_post._id, client_post)
  
  become_visible = ( parent_id ) =>
    # set visible flag
    visible[ parent_id ] = true
    # published saved items
    if saved[ parent_id ]?
      for doc in saved[ parent_id ]
        send( doc )
      saved[ parent_id ] = []
    
  send_when_visible = ( doc ) =>
    visible[ doc.parent_id ] ?= false
    if visible[ doc.parent_id ] or doc._id in ids
      send( doc )
    else
      saved[doc.parent_id] ?= []
      saved[doc.parent_id].unshift( doc )
    # check conditions for becoming visible
    if doc._id in ids
      become_visible( doc._id )
    if doc.author_id is user_id
      become_visible( doc.parent_id )
    
  
  action = (doc, idx) =>
    send_when_visible( doc )
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
