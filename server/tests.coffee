class Tests
  #dummy
  try_nothing: ->
    tron.info( 'a dummy try function' )
  
  try_add_tag: ->
    post = Posts.findOne()
    server_post = new ServerPost( post )
    user_id = Users.findOne()._id
    #add a new tag
    server_post.add_tag( 'tron', user_id )
    #add an existing tag
    grad_this_tag = 'try_add_tag'
    tags = _.keys( server_post.tags )
    for tag in tags
      if not server_post.is_graduated( tag )
        grad_this_tag = tag
    #TODO make sure diff user
    server_post.add_tag( grad_this_tag, user_id )
    
    
  #check if a tag/user_id exists for a given post
  check_add_tag: (server_post, tag, user_id) ->
    #check if tag is present for post
    unless server_post.tags[tag]?
      throw( 'tag not present in post' )
    #check that the tag object has the user_id in users[]
    unless user_id in server_post.tags[tag].users
      throw( 'user not listed for tag.' )
  
  #check if user has exp for a tag
  check_if_user_exp: (user_id, tag, previous_exp) ->
    tron_user = Users.findOne( user_id )
    unless tron_user.experience[tag]?
      throw( 'tag not listed in users exp' )
    unless tron_user.experience[tag] > previous_exp
      throw( 'user expected to gain points for tag' )
  
  #check if a post inserted properly - works
  check_post_insert: ( id, expected_content ) ->
    post = Posts.findOne({'_id': id, 'content': expected_content})
    unless post?
      throw( 'post not found in mongo' )
      
  #check if points were awarded properly
  check_award_points: ( tag, user ) ->
    unless tag in _.keys( user.experience ) && user.experience[tag]?
    #unless true
      throw ( "user does not have experience for #{tag} at the end of add_tag")
  #check if a variable is a number
  check_number: ( num ) ->
    unless _.isNumber( num )
      throw( 'not a number' )
      
tron.test( new Tests() )