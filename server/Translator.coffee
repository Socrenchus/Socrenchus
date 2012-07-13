class Translator
  
  client:
    author_id: ''
    parent_id: ''
    content: ''
    tags: {} # tag: weight
    my_tags: {} # same as tags
    suggested_tags: []
    
  server:
    instance_id: 0
    author_id: 0
    parent_id: ''
    content: 'Hello, I am a post.'
    tags: {} # tag: {users:[], weight:#}

  constructor: ( doc ) ->
    # TODO: check if doc is server or client document
    # assume for now that it is a server document
    @server = doc
    @to_client()

  to_server: ->
  to_client: ->
    user_id = Meteor.call('get_user_id')

    for key in [ 'author_id', 'parent_id', 'content' ]
      @client[key] = @server[key]

    for tag of @server.tags
      @client.tags[tag] = @server.tags[tag].weight
      users = @server.tags[tag].users
      if users? and user_id in users
        @client.my_tags[tag] = @server.tags[tag].weight
        
    for post in Posts.find( 'parent_id': @server.parent_id ).fetch()
      for key of post.tags
        @client.suggested_tags.push( key ) unless key in @client.my_tags