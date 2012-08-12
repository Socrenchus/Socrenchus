Users = Meteor.users
Posts = new Meteor.Collection( "posts" )
Instances = new Meteor.Collection( "instances" )
Notifications = new Meteor.Collection("notifications")


Meteor.publish("my_notifs", ->
  user_id = @userId()
  Session.set('user_id', user_id)
  if user_id?
    return Notifications.find( user: user_id )
)

Meteor.publish("instance", (hostname) ->
  #get instance id...
  instance_query = Instances.find({domain: hostname})
  instance = instance_query.fetch()[0]
  if instance?
    tron.log('instance id: ', instance._id)
    Session.set('instance_id', instance._id)
  else
    user_id = @userId()
    Session.set('user_id', user_id)
    tron.log("Method get_instance_id: instance \"#{hostname}\" does not exist")
    #check email domain
    email_match = false
    current_user_id = user_id
    email_addr = Users.findOne( _id: current_user_id ).email
    [host, domain] = email_addr.split("@")
    if domain is hostname
      email_match = true #success - email address matches hostname
    else
      tron.log('Email domain does not match requested instance domain')
      email_match = false #mismatch - don't allow
    #create new instance
    if email_match
      tron.log('create_instance: Creating new instance')
      #Insert new instance info in db...
      id = Instances.insert({
        admin_id: current_user_id,
        domain: domain
      })
      #...and then set the instance_id session variable to the new instance
      Session.set('instance_id', id)
  return instance_query
)

Meteor.publish("my_posts", ->
  user_id = @userId()
  Session.set('user_id', user_id)
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
        client_post = new ClientPost( doc )
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
    client_post = new ClientPost( doc )
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
