Users = new Meteor.Collection("users_proto")
Posts = new Meteor.Collection("posts")
Instances = new Meteor.Collection("instances")

Meteor.publish("my_user", (user_id) ->
  return Users.find( _id: user_id )
)

Meteor.publish("my_posts", ->
  user_id = Meteor.call('get_user_id')
  uuid = Meteor.uuid
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
    handle = q.observe (
      added: (doc, idx) ->
        ###
        every time a post is added, translate to client schema and publish
        ###
        client_tags = {}
        client_my_tags = {}
        client_votes = {
            'up' : {
              count: 0
              weight: 0
            }
            'down' : {
              count: 0
              weight: 0
            }
          }
        client_my_vote = undefined
        for tag of doc.tags
          client_tags[tag] = doc.tags[tag].weight
          #console.log doc.tags[tag].users
          #doc.tags[tag].users?.push(user_id) #used to test the following loop
          if (doc.tags[tag].users? and (user_id in doc.tags[tag].users))
            #console.log 'personal tag'
            client_my_tags[tag] = doc.tags[tag].weight
        for vote of doc.votes
          #console.log doc.votes[vote]
          client_votes[vote].count = doc.votes[vote].users.length
          client_votes[vote].weight = doc.votes[vote].weight
          if (user_id in doc.votes[vote].users)
            if (vote is 'up')
              client_my_vote = true
            if (vote is 'down')
              client_my_vote = false
        self.set("client_posts", doc._id, {
          author_id : doc.author_id
          content : doc.content
          parent_id : doc.parent_id
          tags: client_tags
          my_tags: client_my_tags
          votes: client_votes
          my_vote: client_my_vote
        })
        self.flush()
      removed: (doc, idx) ->
        console.log 'publish my_post removed:'
      moved: (doc, idx) ->
        console.log 'publish my_post moved:'
      changed: (doc, idx) ->
        console.log 'publish my_post changed:'
        
      
    )
    self.onStop ->
    handle.stop()
    self.unset "client_posts", uuid, [
          'author_id', 'doc.author_id', 'content', 'parent_id', 'tags', 'my_tags', 'my_vote', 'votes'
          ]
    self.flush()
    #return q
  )

