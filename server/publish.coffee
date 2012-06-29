Users = new Meteor.Collection("users_proto")
Posts = new Meteor.Collection("posts")
Instances = new Meteor.Collection("instances")

Meteor.publish("my_user", (user_id) ->
  return Users.find( _id: user_id )
)

Meteor.publish("my_posts", ->
  user_id = Meteor.call('get_user_id')
  self = this
  if user_id
    q = Posts.find( author_id: user_id )
    Session.set( 'my_posts_query', q)
    handle = q.observe (
      added: (doc, idx) ->
        console.log 'some shit got added to my_posts'
        console.log doc
        console.log idx
        self.set('my_posts', user_id,
          author_id : ''
          content : ''
          parent_id : ''
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
        self.flush()
      removed: (doc, idx) ->
        console.log 'some shit got removed from my_posts'
      moved: (doc, idx) ->
        console.log 'some shit got just moved within my_posts'
      changed: (doc, idx) ->
        console.log 'some shit got just changed to my_posts'
    )
    #return q
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

