class SharedPost
  constructor: ( either ) ->
    # define the shared client-server schema
    _.extend( @,
      _id: ''
      parent_id: undefined
      content: ''
      instance_id: ''
      time: ''
    )
    
    for key in [ '_id', 'parent_id', 'content', 'instance_id', 'time' ]
      @[key] = either[key] if either[key]?
       
class ClientPost extends SharedPost
  constructor: ( server ) ->
    # define the client schema
    _.extend( @,
      tags: {} # tag: weight
      my_tags: {} # same as tags
      reply_count: 0
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
    
    user_id = Meteor.call('get_user_id')
    
    super(client)
    
    # init pre change post from server databse
    post = Posts.findOne( _id: client._id ) if client._id?
    is_new = not post?
    
    # check if new post
    if is_new
      _.extend( @, _.pick( client, 'content', 'parent_id' ) )
      @author_id = user_id
      @time = new Date()
    else
      _.extend( @, post )

      # check if user added a new tag
      for tag of client.my_tags
        @tags[tag] ?= { weight: 0 }
        @tags[tag].users ?= []
        unless user_id in @tags[tag].users
          # apply the tag
          @tags[tag].users.push( user_id )
