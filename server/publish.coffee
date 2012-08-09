Users = new Meteor.Collection( "users_proto" )
Posts = new Meteor.Collection( "posts" )
Instances = new Meteor.Collection( "instances" )

Posts.allow?(
  insert: -> true
  update: -> true
  remove: -> false
  fetch: []
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

Meteor.publish("my_user", (user_id) ->
  return Users.find( _id: user_id )
)

Meteor.publish("current_posts", (post_id) ->

  user_id = @userId()
  if user_id? 
  #all the parents and clindren if you have replied.
    ids = []
    ids.push( post_id )
    this_post = post_id
    while Posts.findOne( this_post ).parent_id?
      this_post = Posts.findOne( post_id ).parent_id
      if this_post not in ids
        ids.push( parent_id )
    
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
    q = Posts.find( '_id': in_ids )
    
  
    
    action = (doc, idx) =>
      client_post = new ClientPost( doc )
      @set( "posts", client_post._id, client_post )
      @flush()

    handle = q.observe(
      added: action
      changed: action
    )
    
    @onStop( ->
      handle.stop()
      for post in q.fetch()
        fields = (key for key of Translator.client)
        @unset( "client_posts", post._id, fields )
      @flush()
    )
)


Meteor.publish( "client_users", ->
  q = Meteor.users.find()
  action = ( doc, idx ) =>
    #@set( "users_proto", idx, doc )
    @set( "users_proto", doc._id, { email: doc.email } )
    @flush()
  handle = q.observe(
    added: action
    changed: action
  )
  @onStop( ->
    handle.stop()
    for user in q.fetch()
      @unset( "users_proto", user )
    @flush()
  )
)

