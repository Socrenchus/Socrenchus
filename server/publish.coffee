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
      
  console.log(post_ids)
  
  get_notifs_by_type = (post_id, type) ->
    return Notifications.find(
      {
        '$and':
          [ {post: post_id},
            {type: type} ]
      }
    ).fetch()
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
  if user_id
    q = Posts.find( author_id: user_id )
    Session.set( 'my_posts_query', q)
    return q
)

Meteor.publish("assigned_posts", ->
  user_id = Meteor.call('get_user_id')
  if user_id
    # gather ids of my posts and posts i've replied to
    ids = []
    for item in Session.get( 'my_posts_query' ).fetch()
      ids.push( item['parent_id'] ) if 'parent_id' of item
      ids.push( item['_id'] )
    # query for the children and posts from above
    return Posts.find(
      {
        '$or':
          [
            {
              _id: { '$in': ids }
            },
            {
              parent_id: { '$in': ids }
            }
          ]
      }
    )
)

