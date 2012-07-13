Users = new Meteor.Collection("users_proto")
Posts = new Meteor.Collection("posts")
Instances = new Meteor.Collection("instances")

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
    # query for the children and posts from above
    q = Posts.find(
      {
        '$or':
          [{_id: { '$in': ids }},
            {parent_id: { '$in': ids }}
          ]
      }
    )

    handle = q.observe (
      added: (doc, idx) =>
        t = new Translator( doc )
        @set("posts", t.server._id, t.client)
        @flush()
      removed: (doc, idx) =>
        console.log 'publish my_post removed:'
      moved: (doc, idx) =>
        console.log 'publish my_post moved:'
      changed: (doc, idx) =>
        translator.add_change doc, idx, @
    )
    @onStop( ->
      handle.stop()
      for post in q.fetch()
        fields = (key for key of Translator.client)  
        @unset( "client_posts", post._id, fields )
      @flush()
    )
)

