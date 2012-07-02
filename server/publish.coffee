Users = new Meteor.Collection("users_proto")
Posts = new Meteor.Collection("posts")
Instances = new Meteor.Collection("instances")

Meteor.publish("my_user", (user_id) ->
  return Users.find( _id: user_id )
)

Meteor.publish("my_posts", ->
  user_id = @userId()
  if user_id
    q = Posts.find( author_id: user_id )
    Session.set( 'my_posts_query', q)
    return q
)

Meteor.publish("assigned_posts", ->
  user_id = @userId()
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

