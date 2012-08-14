Users = Meteor.users
Posts = new Meteor.Collection( "posts" )
Instances = new Meteor.Collection( "instances" )
Notifications = new Meteor.Collection("notifications")


Meteor.publish("my_notifs", ->
  user_id = @userId()
  if user_id?
    return Notifications.find( user: user_id )
)

Meteor.publish("my_posts", ->
  user_id = @userId()
  if user_id?
    handle = null
    q = null
    ids = []
    first_action = (item, idx) =>
      # gather ids of my posts and posts i've replied to
      ids.push( item['parent_id'] ) if 'parent_id' of item
      ids.push( item['_id'] )
      
      # query for posts or children of my posts or parents
      in_ids = { '$in': ids }
      in_or_child_of_ids = { '$or': [ {_id: in_ids}, {parent_id: in_ids} ] }
      q = Posts.find( in_or_child_of_ids )
      
      if handle?
        handle.stop()

      action = (doc, idx) =>
        client_post = new ClientPost( doc, user_id )
        @set("posts", client_post._id, client_post)
        @flush()
      
      handle = q.observe(
        added: action
        changed: action
      )
      
    Posts.find( author_id: user_id ).observe(
      added: first_action
      changed: first_action
    )
    
    @onStop( =>
      if q?
        handle.stop()
        q.rewind()
        posts = q.fetch()
        for post in posts
          fields = (key for key of ClientPost)
          @unset( "my_posts", post._id, fields )
        @flush()
    )


)

Meteor.publish("current_posts", (post_id) ->
  #all the parents of the post
  ids = []
  ids.push( post_id )
  this_post = post_id
  while Posts.findOne( this_post )?.parent_id?
    this_post = Posts.findOne( this_post ).parent_id
    if this_post not in ids
      ids.push( this_post )
  
  in_ids = { '$in': ids }
  
  action = (doc, idx) =>
    client_post = new ClientPost( doc, @userId() )
    @set("posts", client_post._id, client_post)
    @flush()
  
  q = Posts.find( '_id': in_ids )
  handle = q.observe(
    added: action
    changed: action
  )
  
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
