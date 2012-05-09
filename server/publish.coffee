Users = new Meteor.Collection("users")
Posts = new Meteor.Collection("posts")
Tags = new Meteor.Collection("tags")

Meteor.publish("my_user", (user_id) ->
  return Users.find( _id: user_id )
)

Meteor.publish("my_posts", ->
  user_id = Session.get('user_id')
  if user_id
    tags = Tags.find( user_id: user_id, name: ',assignment' ).fetch()
    return Posts.find( _id: {'$in':( t.post_id for t in tags )} )
)

Meteor.startup( ->
  Session.set 'user_id', Users.findOne( {} )['_id']
)