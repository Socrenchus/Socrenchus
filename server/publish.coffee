Users = new Meteor.Collection("users_proto")
Posts = new Meteor.Collection("posts")
Instances = new Meteor.Collection("instances")

Meteor.publish("my_user", (user_id) ->
  return Users.find( _id: user_id )
)

Meteor.publish("my_posts", ->
  user_id = Meteor.call('get_user_id')
  self = this
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
    #my_post_query session variable depricated
    #q = Posts.find( author_id: user_id )
    #Session.set( 'my_posts_query', q)
    handle = q.observe(
      added: (doc, idx) ->
        translator.add_change(doc, idx, self)
      removed: (doc, idx) ->
        console.log('publish my_post removed:')
      moved: (doc, idx) ->
        console.log('publish my_post moved:')
      changed: (doc, idx) ->
        translator.add_change(doc, idx, self)
    )
    self.onStop( ->
      handle.stop()
      #self.unset("client_posts", uuid, [
      self.unset("client_posts", [
        'author_id', 'doc.author_id', 'content',
        'parent_id', 'tags', 'my_tags', 'my_vote', 'votes'
      ])
    )
    self.flush()
    #return q
  )

