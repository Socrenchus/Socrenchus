Users = new Meteor.Collection("users_proto")
Posts = new Meteor.Collection("posts")
Instances = new Meteor.Collection("instances")

Meteor.publish("my_user", (user_id) ->
  return Users.find( _id: user_id )
)

filter_posts = ->
  res = [];
  @forEach((doc) ->
    #doc.content = 'troll'
    
    res.push(doc)
  )
  return res

Meteor.publish("my_posts", ->
  user_id = Meteor.call('get_user_id')
  if user_id
    q = Posts.find( { author_id: user_id } )
    Session.set( 'my_posts_query', q)
    q.__proto__.fetch = filter_posts
    return q
)

Meteor.publish("assigned_posts", ->
  user_id = Meteor.call('get_user_id')
  if user_id
    ids = []
    for item in Session.get( 'my_posts_query' ).fetch() #For each of my posts
      ids.push item['parent_id'] if 'parent_id' of item #Add the parent's id
      ids.push item['_id']                              #Add my post's id
    q = Posts.find( {'$or':                          #Return all posts who
        [ 
          {_id: {'$in':ids}},                           #are mine, or my parent's
          {parent_id: {'$in':ids}}                      #or my siblings, or my children.
        ] 
      }
    )
    q.__proto__.fetch = filter_posts
    return q
)

