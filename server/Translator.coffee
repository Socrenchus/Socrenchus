class SharedPost
  @schema:
    _id: ''
    author_id: ''
    parent_id: undefined
    content: ''
  
  constructor: ( either ) ->
    _.extend( @, SharedPost.schema )
    for key in [ '_id', 'author_id', 'parent_id', 'content' ]
      @[key] = either[key] if either[key]?
       
class ClientPost extends SharedPost
  @schema:
    tags: {} # tag: weight
    my_tags: {} # same as tags
    suggested_tags: []
  
  constructor: ( server ) ->
    _.extend( @, ClientPost.schema )
    user_id = Meteor.call('get_user_id')
    
    super server

    for tag of server.tags
      @tags[tag] = server.tags[tag].weight
      users = server.tags[tag].users
      if users? and user_id in users
        @my_tags[tag] = server.tags[tag].weight
        
    for post in Posts.find( 'parent_id': server.parent_id ).fetch()
      for key of post.tags
        @suggested_tags.push( key ) unless key in @my_tags

class ServerPost extends SharedPost
  @schema:
    instance_id: ''
    tags: {} # tag: {users:[], weight:#}
  
  constructor: ( client ) ->
    _.extend( @, ServerPost.schema )
    user_id = Meteor.call('get_user_id')
    
    super client
    
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
          @tags[tag].users.push( user_id )
    
      
