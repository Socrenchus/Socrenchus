class @ClientPost extends @SharedPost
  constructor: ( server, user_id ) ->
    # define the client schema
    _.extend( @,
      tags: {} # tag: weight
      my_tags: {} # same as tags
      suggested_tags: []
      reply_count: 0
    )
    super(server)
    return unless user_id?
    
    for tag of server.tags
      if @is_graduated( tag, server )
        @tags[tag] = server.tags[tag].weight
      users = server.tags[tag].users
      if users? and user_id in users
        @my_tags[tag] = server.tags[tag].weight
    
    suggested_tags = {}
    for key of @my_tags
      suggested_tags[key] = 'mine'
    for post in Posts.find( 'parent_id': server.parent_id ).fetch()
      for key of post.tags
        suggested_tags[ key ] ?= 'suggested'
    for key, value of suggested_tags
      @suggested_tags.push( key ) if value is 'suggested'
        
    author = Meteor.users.findOne( '_id': server.author_id )
    if author?
      @author = _.pick( author, '_id', 'name', 'username' )
      @author.email = author.emails[0].address
      
    @reply_count = Posts.find({parent_id: server._id}).count()
