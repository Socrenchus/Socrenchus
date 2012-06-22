Users = new Meteor.Collection("users_proto")
Posts = new Meteor.Collection("posts")
Instances = new Meteor.Collection("instances")

Meteor.publish("my_user", (user_id) ->
  return Users.find( _id: user_id )
)

Meteor.publish("my_posts", ->
  user_id = Meteor.call('userId')
  if user_id
    q = Posts.find( author_id: user_id )
    Session.set( 'my_posts_query', q)
    return q
)

Meteor.publish("assigned_posts", ->
  user_id = Meteor.call('userId')
  if user_id
    ids = []
    for item in Session.get( 'my_posts_query' ).fetch() #For each of my posts
      ids.push item['parent_id'] if 'parent_id' of item #Add the parent's id
      ids.push item['_id']                              #Add my post's id
    return Posts.find( {'$or':                          #Return all posts who
        [ 
          {_id: {'$in':ids}},                           #are mine, or my parent's
          {parent_id: {'$in':ids}}                      #or my siblings, or my children.
        ] 
      } 
    )
)

