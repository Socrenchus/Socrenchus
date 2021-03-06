class @ServerPost extends @SharedPost
  constructor: ( client, user_id ) ->
    # define the server schema
    _.extend( @,
      tags: {} # tag: {users:[], weight:#}
    )
        
    super(client)
    
    # init pre change post from server databse
    post = Posts.findOne( _id: client._id ) if client._id?
    is_new = not post?
    
    # check if new post
    if is_new
      _.extend( @, _.pick( client, 'content', 'parent_id' ) )
      @author_id = user_id
      throw 'Need to be logged in to post.' unless @author_id?
      already_replied =
        parent_id: @parent_id,
        author_id: @author_id
      if @parent_id? and Posts.findOne( already_replied )?
        throw 'Can\'t reply twice to the same post.'
      
      #Alert post author that his post was replied to
      Notifications.insert( {
        user: Posts.findOne(_id: @parent_id)?.author_id
        type: 0
        post: @_id
        other_user: @author_id
        points: 0
        tag: tag
        timestamp: new Date()
        seen: false
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
    already_graduated = @is_graduated( tag, @ )
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
    graduated = @is_graduated( tag, @ )
    
    if not already_graduated and graduated
      @award_points( @tags[tag].users, tag )
      user = Users.findOne('_id': user_id)
      tron.test( 'check_award_points', tag, user )
    tron.test( 'check_add_tag', @, tag, user_id)

  
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
        user: user_id
        type: unless user_id is @author_id then 1 else 2
        post: @_id
        points: reward
        tag: tag
        timestamp: new Date()
        seen: false
      } )
      
