Users = new Meteor.Collection("users_proto")
Posts = new Meteor.Collection("posts")
Instances = new Meteor.Collection("instances")

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