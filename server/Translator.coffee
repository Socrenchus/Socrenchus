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
    console.log 'serverPost costructor'

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
    console.log( 'add_tag', tag, user_id)
    # check if already graduated
    already_graduated = @is_graduated( tag )
    # add the tag
    @tags[tag].users.push( user_id ) 
    # add user's post experience to the tag
    @tags[tag].weight += @get_user_post_experience( user_id )
    # check if graduated
    graduated = @is_graduated( tag )
    if not already_graduated and graduated
      #if true
      @award_points( @tags[tag].users, tag )
      user = Users.findOne('_id': user_id)
      #console.log 'the user:', user
      ###
      tron.test( ->
        #check if the user has some experience for the tags
        tron.info( 'after award_points user:', user )
        unless tag in _.keys( user.experience ) && user.experience[tag].weight?
        #unless true
          tron.error( "user does not have experience for #{tag} at the end of add_tag")
        
      )###
    tron.log( 'before check add tag' )
    tron.test( 'check_add_tag', @, tag, user_id)
    tron.log( 'after check add tag' )
    console.log( tron.subscriptions )
  
  
  is_graduated: ( tag ) =>
    # TODO: Improve this function
    return @tags[tag].weight > 1
  
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
        # multiply normalize tag weight by user's tag experience
        # sum all those up
        users_post_experience += weights[tag] * user.experience[tag]
      # return the sum
      return users_post_experience
    else return 1 # TODO: Default to some function of experience

  award_points: ( users, tag ) =>
    reward = @tags[tag].weight / users.length
    #for user of Users.find( '_id': { '$in': users } )
    for user_id in users  
      user_doc = Users.findOne( user_id )
      # add reward to user for tag
      q = {'_id': '', '$set': {'experience': {}} }
      q['_id'] = user_doc['_id']
      console.log "user_doc.['_id']", user_doc['_id']
      exp_obj = {}
      #copy existing tag exp
      for u_tag, exp of user_doc.experience
        #exp_obj['$set'][u_tag] = exp
        exp_obj[u_tag] = exp
      #insert the new tag exp
      exp_obj[tag] = reward
      q['$set']['experience'] = exp_obj
      ###
      tron.test( ->
        tron.log( 'the query', q )
        tron.log( 'query returns', Users.update(q) )
      )###
      
Meteor.startup( ->
  tron.test()
)
  
