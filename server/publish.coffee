Users = new Meteor.Collection("users_proto")
Posts = new Meteor.Collection("posts")
Instances = new Meteor.Collection("instances")

Meteor.publish("my_user", (user_id) ->
  return Users.find( _id: user_id )
)

#i dont know if this is really the current user, 
#looks like calling get_user_id, too many times causes stack overflow error.
#this is a workaround for the same.
current_user = 'dummy'

filter_posts = ->
  res = []
  #console.log current_user
  @forEach((doc) ->
    #client schema is outlined here.
    client_doc = {
      author_id : ''
      content : ''
      instance_id : ''
      parent_id : ''
      tags : {
        content: ''
        weight: 0
      }
      my_tags : {
        content: ''
        weight: 0
      }
      my_vote : null
      vote_weight : 0
    }
    client_doc._id = doc._id
    client_doc.author_id = doc.author_id
    client_doc.content = doc.content
    client_doc.instance_id = doc.instance_id
    client_doc.parent_id = doc.parent_id
    #leaving instance_id intact for now, consider removing this field
    
    #find out if user upvoted or downvoted
    if (current_user ?= username in doc.votes['up'].users)
      client_doc.my_vote = true
    else if (current_user ?= username in doc.votes['down'].users)
      client_doc.my_vote = false
    
    #votes only visible if user has voted
    if client_doc.my_vote?
      up_votes = 0
      down_votes = 0
      up_votes = doc.votes?['up'].users.length?
      down_votes = doc.votes?['down'].users.length?
      #need a better vote_weight function
      client_doc.vote_weight = up_votes - down_votes
    
    #only graduated tags are visible
    
    tag_list = {}
    my_tag_list = {}
    for tag in doc.tags?
      #needs a better function to determine if a tag has graduated,
      #graduated if more than one user.
      if (tag.users.length > 1)
        tag_list.push ({content: tag[0], weight: tag[0].weight})
        
      if (current_user is user in tag.users)
        my_tag_list.push ({content: tag[0], weight: tag[0].weight})
        
    #TODO: tag_list seems to be empty, maybe becuse the user has not tagged anything yet
    
    client_doc.tags = tag_list
    client_doc.my_tags = my_tag_list
    
    #console.log(client_doc)
    res.push(client_doc)
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
    current_user = user_id
    q.__proto__.fetch = filter_posts
    return q
)

