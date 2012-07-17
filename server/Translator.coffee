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
      # award points to users
  
  is_graduated: ( tag ) =>
    # TODO: Improve this function
    return @tags[tag].weight > 1
  
  get_user_post_experience: ( user_id ) =>
    # loop through tags in post (aka this)
    # normalize tag weights
    # multiply normalize tag weight by user's tag experience
    # sum all those up
    # return sum
  
  award_points: ( users, tag ) =>
    reward = @tags[tag].weight / users.length
    for user in Users.find( '_id': { '$in': users } )
      # add reward to user for tag

class ServerPost extends SharedPost
  constructor: ( client ) ->
    #define server side schema
    _.extend(@,
      tags: {} #'tag': {users: [], weight: num}
    )
    super( client )
    user_id = Meteor.call('get_user_id')
    mongo_post = Posts.findOne(client._id)
    if mongo_post?
      #console.log 'its a post/update action'
      #translate client side tag to server format
      #all tags
      for tag, weight of client.tags
        #console.log tag, weight
        @tags["#{tag}"] = mongo_post.tags[tag] 
      #tags specific to user  
      for tag, weight of client.my_tags
        @add_tag(tag, weight, user_id)
      #update document to mongo
      Posts.update({'_id': @_id}, {'$set': {'tags': @tags}})
    else
      console.log 'its a post/insert action'
    
  #a method to check if a users tag action caused it to graduate.
  is_graduated: (tag) =>
    graduated = false
    #TODO update to something better than just >2
    if @tags[tag]?.weight > 1
      console.log 'tag graduates'
      graduated = true
    return graduated
 
  inc_exp: (tag, points) =>
    #the author of the post gets a fraction of exp for all tags
    author = Users.findOne({'_id': @author_id})
    num_tags = _.keys(author.experience).length
    exp_gain = points/num_tags
    for tag of author.experience
      q = {'_id': '', '$inc': ''}
      q._id = @author_id
      q['$inc'] = "experience[#{tag}], #{exp_gain}"
      Users.update(q)
    #all users gain exp for this particular tag
    for user in @tags[tag].users
      q = {'_id': '', '$inc': ''}
      q._id = user
      q['$inc'] = "experience[#{tag}], #{points}"
      Users.update(q)
      
  #a method to handle tag insersion
  add_tag: ( tag ) =>
    tron.log( 'serverLogic/add_tag' )
    #upvoting an existing tag
    if @tags[tag]?
      #check if this tag insertion graduates the tag
      if @tag_graduates(tag)
        #if yes, give points to author and taggers
        @inc_exp(tag)
      #add user to the list of users for the tag
      @tags["#{tag}"].users.push(tagger_id)
      @tags["#{tag}"].weight++
    #inserting a new tag
    else
      #add the tag to the doc and update weight
      tag_obj = {}
      tag_obj["#{tag}"] = {users: [], weight: 1}
      tag_obj["#{tag}"].users.push(tagger_id)
      for key, val of Posts.findOne({'_id': @_id}).tags
        tag_obj["#{key}"] = val
      #console.log 'should  be all the tags', tag_obj
      @tags = tag_obj
      
    #add user.experience[tag] : 0
    q = {_id: '', $set:''}
    q._id = tagger_id
    exp_obj = {}
    for e_tag, exp of Users.findOne({'_id': tagger_id}).experience
      exp_obj["#{e_tag}"] = exp
    exp_obj["#{tag}"] = 1
    q.$set = {experience: exp_obj}
    Users.update(q)