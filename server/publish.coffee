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
    #working shit
    #q = Posts.find( author_id: user_id )
    #Session.set( 'my_posts_query', q)
    handle = q.observe (
      added: (doc, idx) ->
        ###
        console.log 'publish my_post added:'
        self.set('my_posts', idx,
          author_id : doc.author_id
          content : doc.content
          parent_id : doc.parent_id
          tags : {
            #the tag text and corrosponding weight
            'tag_name' :  0
          }
          my_tags : {
            'tag_name' :  0
          }
          my_vote : undefined
          votes :{
            'up' : {
              count: 0
              weight: 0
            }
            'down' : {
              count: 0
              weight: 0
            }
          }
        )
        
        ###
        client_tags = {}
        client_my_tags = {}
        client_votes = {}
        client_my_vote = undefined
        for tag of doc.tags
          client_tags[tag] = doc.tags[tag].weight
          #console.log doc.tags[tag].users
          #doc.tags[tag].users?.push(user_id) #used to test the following loop
          if (doc.tags[tag].users? and (user_id in doc.tags[tag].users))
            #console.log 'personal tag'
            client_my_tags[tag] = doc.tags[tag].weight
        
        #console.log doc
        for vote of doc.votes
          #TODO:need to fix bootstrap before fixing this
          console.log 'votes thingie in publish/added'
          console.log vote
          console.log doc.votes['up']
          #console.log doc
        self.set("client_posts", doc._id, {
          author_id : doc.author_id
          content : doc.content
          parent_id : doc.parent_id
          tags: client_tags
          my_tags: client_my_tags
          votes: client_votes
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

