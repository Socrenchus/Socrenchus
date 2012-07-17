class SharedPost
  constructor: ( either ) ->
    # define the shared client-server schema
    _.extend( @,
      _id: ''
      author_id: ''
      parent_id: undefined
      content: ''
    )
    
    for key in [ '_id', 'author_id', 'parent_id', 'content' ]
      @[key] = either[key] if either[key]?
       
class ClientPost extends SharedPost
  constructor: ( server ) ->
    # define the client schema
    _.extend( @,
      tags: {} # tag: weight
      my_tags: {} # same as tags
      suggested_tags: []
    )

    user_id = Meteor.call('get_user_id')
    
    super(server)
    
    for tag of server.tags
      
      @tags[tag] = server.tags[tag].weight
      users = server.tags[tag].users
      if users? and user_id in users
        @my_tags[tag] = server.tags[tag].weight
        
    for post in Posts.find( 'parent_id': server.parent_id ).fetch()
      for key of post.tags
        @suggested_tags.push( key ) unless key in @my_tags

class ServerPost extends SharedPost
  constructor: ( client ) ->
    # define the server schema
    _.extend( @,
      instance_id: ''
      tags: {} # tag: {users:[], weight:#}
    )
    
    user_id = Meteor.call('get_user_id')
    
    super(client)
    
    # init pre change post from server databse
    post = Posts.findOne( _id: client._id ) if client._id?
    is_new = not post?
    
    # check if new post
    if is_new
      _.extend( @, _.pick( client, 'content', 'parent_id' ) )
      @author_id = user_id
    else
      _.extend( @, post )

      # check if user added a new tag
      for tag of client.my_tags
        @tags[tag] ?= { weight: 0 }
        @tags[tag].users ?= []
        unless user_id in @tags[tag].users
          # apply the tag
          @add_tag( tag, user_id )
  
  add_tag: ( tag, user_id ) =>
    # check if already graduated
    already_graduated = @is_graduated( tag )
    # add the tag
    @tags[tag].users.push( user_id )
    # add user's post experience to the tag
    @tags[tag].weight += @get_user_post_experience( user_id )
    # check if graduated
    graduated = @is_graduated( tag )
    if not already_graduate and graduated
      award_points( @tags[tag].users, tag )
  
  is_graduated: ( tag ) =>
    # TODO: Improve this function
    return @tags[tag].weight > 1
  
  get_user_post_experience: ( user_id ) =>
    # loop through tags in post (aka this)
    weights = {}
    weight_total = 0
    for tag, obj of @tags
      weights[tag] = obj.weight 
      weight_total += obj.weight
    unless weight_total is 0
      users_post_experience = 0
      for tag, weight of weights
        # normalize tag weights
        weights[tag] /= weight_total
        user = Users.findOne('_id': user_id)
        # multiply normalize tag weight by user's tag experience
        # sum all those up
        users_post_experience += weights[tag] * user.experience[tag]
      # return the sum
      return users_post_experience
    else return 1 # TODO: Default to some function of experience

  award_points: ( users, tag ) =>
    reward = @tags[tag].weight / users.length
    for user in Users.find( '_id': { '$in': users } )
      # add reward to user for tag
      q = {'_id': '', '$set': {} }
      q['_id'] = user['_id']
      exp_obj = {}
      for u_tag, exp of user.experience
        exp_obj['$set'][u_tag] = exp
      exp_obj['$set'][u_tag] = reward
      q['$set'] = exp_obj
      Users.update(q)
    
