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
      tags : {content: [], weight: []}
      my_tags : {content: [], weight: []}
      my_vote : null
      vote_weight : 0
    }
    
    client_doc.author_id = doc.author_id
    client_doc.content = doc.content
    client_doc.instance_id = doc.instance_id
    client_doc.parent_id = doc.parent_id
    #leaving instance_id intact for now, consider removing this field
    
    #find out if user upvoted or downvoted
    if (current_user ?= username in doc.votes['up'].users)
      client_doc.my_vote = 'up'
    else if (current_user ?= username in doc.votes['down'].users)
      client_doc.my_vote = 'down'
    
    #votes only visible if user has voted
    if (client_doc.my_vote != null)
      up_votes = 0
      down_votes = 0
      up_votes = doc.votes?['up'].users.length?
      down_votes = doc.votes?['down'].users.length?
      #need a better vote_weight function
      client_doc.vote_weight = up_votes - down_votes
    
    #only graduated tags are visible
    #needs a better function to determine if a tag has graduated
    tag_list = {content: [], weight: []}
    my_tag_list = {content: [], weight: []}
    for tag in doc.tags?
      if (tag.users.length > 1)
        tag_list.content.push tag.toString
        tag_list.weight.push tag.weight
      if (current_user is user in tag.users)
        my_tag_list.content.push tag.toString
        my_tag_list.weight.push tag.weight
    #TODO: tag_list seems to be empty, 
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
    current_user = user_id
    q.__proto__.fetch = filter_posts
    return q
)

