#test_user_id = ''
#test_post_id = ''

tron.test(
  ###
  try_insert_user: ->
    @test_user_id = Users.insert(
      'email': 'tron@socrench.us'
      'experience': {
        'tron_tag': 0
      }
    )
    tron.test( 'check_user', test_user_id )
  ###
  
  try_add_tag: ->
    test_post_id = Posts.insert(
      'content': 'tron'
      'tags': {
        'tron_tag': {
          'users': [Users.findOne()]
          'weight': 0
        }
      }
    )
    post = Posts.findOne(  )
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
    server_post.add_tag( grad_this_tag, user_id )

  ###
  try_clean_up: ->
    Posts.remove( test_post_id )
    Users.remove( test_user_id )
    tron.test( 'check_post_remove', test_post_id )
    tron.test( 'check_user_remove', test_user_id )
  ###
    
    
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
  

      
  #check if user has experience for a tag
  check_award_points: ( tag, user ) ->
    unless tag in _.keys( user.experience ) && user.experience[tag]?
    #unless true
      throw ( "user does not have experience for #{tag} at the end of add_tag")
  
  check_number: ( num ) ->
    unless _.isNumber( num )
      throw( 'not a number' )
  
  ###  
  check_user: ( user_id ) ->
    unless Users.findOne( user_id )?
      throw 'user not found'
      
  check_post_remove: ( post_id ) ->
    if Posts.findOne( post_id )?
      throw 'post not removed in mongo'
      
  check_user_remove: ( user_id ) ->
    if Users.findOne( user_id )?
      throw 'user not removed in mongo'
  ###
)