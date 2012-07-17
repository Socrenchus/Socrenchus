Users = new Meteor.Collection("users_proto")
Posts = new Meteor.Collection("posts")
Instances = new Meteor.Collection("instances")
Notifications = new Meteor.Collection("notifications")

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
  
  console.log(groups)
  
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

Meteor.publish("my_user", (user_id) ->
  return Users.find( _id: user_id )
)

Meteor.publish("my_posts", ->
  user_id = Meteor.call('get_user_id')
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
      @set("posts", client_post._id, client_post)
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

