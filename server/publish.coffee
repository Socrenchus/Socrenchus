Users = Meteor.users
Posts = new Meteor.Collection( "posts" )
Instances = new Meteor.Collection( "instances" )
Notifications = new Meteor.Collection("notifications")


Meteor.publish("my_notifs", ->
  user_id = @userId()
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


#publish posts
Meteor.publish( "my_posts", (post_id) ->
  ids = []
  #if post_id is given, publish a path to the root post.
  if post_id?
      ids.push( post_id )
      this_post = post_id
      while Posts.findOne( this_post )?.parent_id?
        this_post = Posts.findOne( this_post ).parent_id
        if this_post not in ids
          ids.push( this_post )
  
  
  #if author, publish the entire tree that resulted from the post.
  user_id = @userId()
  if user_id?
    author_posts = Posts.find({'author_id': user_id}).fetch() 
    if author_posts
      for ap in author_posts
        ch_ids = []
        if ap.children_ids?
          for id in ap.children_ids
            ch_ids.push( id )
        for cid in ch_ids
          p = Posts.findOne( cid )
          if p? and p.children_ids?
            n_chids = Posts.findOne( cid ).children_ids
            for n_chid in n_chids
              if n_chid not in ch_ids
                ch_ids.push( n_chid )
        for id in ch_ids
          if id not in ids
            ids.push( id )
            
  q = Posts.find( {'_id': {'$in': ids} } )
  
  action = (doc, idx) =>
    client_post = new ClientPost( doc, user_id )
    @set("posts", client_post._id, client_post)
    @flush()
  
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