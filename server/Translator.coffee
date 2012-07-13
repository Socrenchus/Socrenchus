class ClientPost
  
  
  constructor: ( server ) ->
    @_id = ''
    @author_id = ''
    @parent_id = ''
    @content = ''
    @tags = {} # tag= weight
    @my_tags = {} # same as tags
    @suggested_tags = []
  
    user_id = Meteor.call('get_user_id')

    for key in [ '_id', 'author_id', 'parent_id', 'content' ]
      @[key] = server[key]
      
    for tag of server.tags
      @tags[tag] = server.tags[tag].weight
      users = server.tags[tag].users
      if users? and user_id in users
        @my_tags[tag] = server.tags[tag].weight
        
    for post in Posts.find( 'parent_id': server.parent_id ).fetch()
      for key of post.tags
        unless key in @my_tags || key in @suggested_tags
          @suggested_tags.push( key )

class ServerPost
  _id: ''
  instance_id: 0
  author_id: 0
  parent_id: ''
  content: 'Hello, I am a post.'
  tags: {} # tag: {users:[], weight:#}
  
  constructor: ( client ) ->
