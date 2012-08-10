Users = new Meteor.Collection( "users_proto" )
Posts = new Meteor.Collection( "posts" )
Instances = new Meteor.Collection( "instances" )
Notifications = new Meteor.Collection("notifications")

Posts.allow?(
  insert: -> true
  update: -> true
  remove: -> false
  fetch: []
)

Meteor.publish("my_notifs", ->
  uuid = Meteor.uuid()
  self = this

  #TODO: only return notifications in which the 'user'
  #      field matches the current user_id
  my_notifs = Notifications.find()
  
  post_ids = []
  for notif in my_notifs.fetch()
    if not (notif.post in post_ids)
      post_ids.push(notif.post)
  
  get_notifs_by_type = (post_id, type) ->
    group = Notifications.find(
      {
        '$and':
          [ {post: post_id},
            {type: type} ]
      }
    ).fetch()
    #Each group has its most recent notification first
    group.sort( (a,b) ->
      return a.timestamp < b.timestamp
    )
    return group
  groups = []
  for post in post_ids
    replies = get_notifs_by_type(post, 0)
    if replies.length > 0
      groups.push(replies)
    my_tags = get_notifs_by_type(post, 1)
    if my_tags.length > 0
      groups.push(my_tags)
    tagged = get_notifs_by_type(post, 2)
    if tagged.length > 0
      groups.push(tagged)
  
  #Sort all groups by their most recent notification
  groups.sort( (a,b) ->
    return a[0].timestamp < b[0].timestamp
  )
  
  handle = my_notifs.observe (
    added: (doc, idx) ->
      self.set("notifications", uuid, {groups})
      self.flush()
  )
  
  #cleanup
  self.onStop( ->
    handle.stop()
    self.unset("my_notifs", uuid, ["posts"])
    self.flush()
  )
)

Meteor.publish("instance", (hostname) ->
  user_id = Session.get('user_id')
  #get instance id...
  instance_query = Instances.find({domain: hostname})
  instance = instance_query.fetch()[0]
  if instance?
    tron.log('instance id: ', instance._id)
    Session.set('instance_id', instance._id)
  else
    tron.log("Method get_instance_id: instance \"#{hostname}\" does not exist")
    #check email domain
    email_match = false
    current_user_id = Meteor.call('get_user_id')
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
  if user_id?
    handle = null
    q = null
    first_action = (item, idx) =>
      # gather ids of my posts and posts i've replied to
      ids = []
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
        posts = q.fetch()
        handle.stop()
        for post in posts
          fields = (key for key of ClientPost)
          @unset( "my_posts", post._id, fields )
        @flush()
    )


)

Meteor.publish("current_posts", (post_id) ->

  user_id = @userId()
  if user_id? 
  #all the parents of the post
    ids = []
    ids.push( post_id )
    this_post = post_id
    while Posts.findOne( this_post ).parent_id?
      this_post = Posts.findOne( this_post ).parent_id
      if this_post not in ids
        ids.push( this_post )
    
    #also add child posts if user has replied
    children = Posts.find( 'parent_id': post_id ).fetch()
    replied = false
    for child_post in children
      if child_post.author_id = user_id
        replied = true
    if replied
      child_posts = Posts.find( 'parent_id': post_id ).fetch()
      while Posts.findOne( 'parent_id':{'$in': child_posts } )?
        child_posts =  Posts.findOne( 'parent_id':{'$in': child_posts } )
        for child_post in child_posts
          if child_post._id not in ids
            ids.push( child_post._id )
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
      posts = q.fetch()
      handle.stop()
      for post in posts
        fields = (key for key of ClientPost)
        @unset( "client_posts", post._id, fields )
      @flush()
    )
)
