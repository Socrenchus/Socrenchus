class SharedPost
  constructor: ( either ) ->
    # define the shared client-server schema
    _.extend( @,
      _id: ''
      parent_id: undefined
      content: ''
      instance_id: ''
      time: new Date()
    )
    
    for key in [ '_id', 'parent_id', 'content', 'instance_id', 'time' ]
      @[key] = either[key] if either[key]?
       
class ClientPost extends SharedPost
  constructor: ( server ) ->
    # define the client schema
    _.extend( @,
      tags: {} # tag: weight
      my_tags: {} # same as tags
      suggested_tags: []
      reply_count: 0
    )

    user_id = Session.get('user_id')
    
    super(server)
    
    for tag of server.tags
      @tags[tag] = server.tags[tag].weight
      users = server.tags[tag].users
      if users? and user_id in users
        @my_tags[tag] = server.tags[tag].weight
    
    for post in Posts.find( 'parent_id': server.parent_id ).fetch()
      for key of post.tags
        @suggested_tags.push( key ) unless key in @my_tags
        
    author = Meteor.users.findOne( '_id': server.author_id )
    if author?
      @author = _.pick( author, '_id', 'emails', 'name' )
      
    @reply_count = Posts.find({parent_id: server._id}).count()
    
class ServerPost extends SharedPost
  constructor: ( client ) ->
    # define the server schema
    _.extend( @,
      instance_id: ''
      tags: {} # tag: {users:[], weight:#}
    )
    
    user_id = Session.get('user_id')
    
    super(client)
    
    # init pre change post from server databse
    post = Posts.findOne( _id: client._id ) if client._id?
    is_new = not post?
    
    # check if new post
    if is_new
      _.extend( @, _.pick( client, 'content', 'parent_id' ) )
      @author_id = user_id
      
      #Alert post author that his post was replied to
      Notifications.insert( {
        user: Posts.find(_id: @parent_id).author_id
        type: 0
        post: @_id
        other_user: @author_id
        points: 0
        tag: tag
        timestamp: new Date()
      } )
    else
      _.extend( @, post )
      
      # check if user added a new tag
      for tag, weight of client.my_tags
        @tags[tag] ?= { weight: 0 }
        @tags[tag].users ?= []
        unless user_id in @tags[tag].users
          # apply the tag
          @add_tag( tag, user_id )
  
  add_tag: ( tag, user_id ) =>
    # check if already graduated
    already_graduated = @is_graduated( tag )
    # add the tag
    if not @tags[tag]?
      @tags[tag] = {
        users: []
        weight: 0
      }
    @tags[tag].users.push( user_id )
    
    # add user's post experience to the tag
    @tags[tag].weight += @get_user_post_experience( user_id )
    # check if graduated
    graduated = @is_graduated( tag )
    
    if not already_graduated and graduated
      @award_points( @tags[tag].users, tag )
      user = Users.findOne('_id': user_id)
      tron.test( 'check_award_points', tag, user )
    tron.test( 'check_add_tag', @, tag, user_id)
  
  
  is_graduated: ( tag ) =>
    # TODO: Improve this function
    grad = false
    if @tags[tag]?
      grad = @tags[tag].users.length > 1
    else grad = false
    return grad

    
  get_user_post_experience: ( user_id ) =>
    weights = {}
    weight_total = 0
    # loop through tags in post (aka this)
    for tag, obj of @tags
      weights[tag] = obj.weight
      weight_total += obj.weight
    unless weight_total is 0
      users_post_experience = 0
      for tag, weight of weights
        # normalize tag weights
        weights[tag] /= weight_total
        user = Users.findOne('_id': user_id)
        if not user.experience?
          user.experience = {}
        # multiply normalize tag weight by user's tag experience
        # sum all those up
        if user.experience[tag]?
          user_exp = user.experience[tag]
        else
          user_exp = 0  #defaults to 0
        users_post_experience += weights[tag] * user_exp
      # return the sum
      return users_post_experience
    else return 1 # TODO: Default to some function of experience
  
  award_points: ( users, tag ) =>
    reward = @tags[tag].weight / users.length
    tron.test( 'check_number', reward )
    
    #Alert post author that a tag graduated on his post
    Notifications.insert( {
      user: @author_id
      type: 2
      post: @_id
      points: reward
      tag: tag
      timestamp: new Date()
    } )
    
    for user_id in users
      user_doc = Users.findOne( user_id )
      # add reward to user for tag
      q = {
        '$set':
          {'experience': {}}
      }
      exp_obj = {}
      #copy existing tag exp
      for u_tag, exp of user_doc.experience
        #exp_obj['$set'][u_tag] = exp
        exp_obj[u_tag] = exp
      #the new tag exp, increment/insert
      past_exp = 0
      if exp_obj[tag]?
        past_exp = exp_obj[tag]
      exp_obj[tag] = reward + past_exp
      q['$set']['experience'] = exp_obj
      Users.update( {'_id': user_doc._id}, q )
      tron.test( 'check_if_user_exp', user_id, tag, past_exp )
      
      #Alert taggers that their tag graduated
      Notifications.insert( {
        user: @author_id
        type: 1
        post: @_id
        points: reward
        tag: tag
        timestamp: new Date()
      } )
      
