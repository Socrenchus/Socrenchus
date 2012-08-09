Users = new Meteor.Collection( "users_proto" )
Posts = new Meteor.Collection( "posts" )
Instances = new Meteor.Collection( "instances" )

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

Meteor.publish("my_posts", ->
  user_id = @userId()
  if user_id?
    # gather ids of my posts and posts i've replied to
    ids = []
    for item in Posts.find( author_id: user_id ).fetch()
      ids.push( item['parent_id'] ) if 'parent_id' of item
      ids.push( item['_id'] )
    # query for posts or children of my posts or parents
    in_ids = { '$in': ids }
    in_or_child_of_ids = { '$or': [ {_id: in_ids}, {parent_id: in_ids} ] }
    q = Posts.find( in_or_child_of_ids )

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
  q = Users.find()
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

