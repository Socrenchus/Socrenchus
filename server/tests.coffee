class Tests
  #dummy
  try_nothing: ->
    tron.info( 'a dummy try function' )
    
    
  #check if a tag/user_id exists for a given post
  check_add_tag: (server_post, tag, user_id) ->
      if false
        throw 'check_tagged manual fail'
      #check if tag is present for post
      unless server_post.tags[tag]?
        throw( 'tag not present in post' )
      #check that the tag object has the user_id in users[]
      unless user_id in server_post.tags[tag].users
        throw( 'user not listed for tag.' )
  
  #check if user has exp for a tag
  check_if_user_exp: (user_id, tag, previous_exp) ->
    tron_user = Users.findOne( user_id )
    tron.log( 'check_if_user_exp' )
    if false
      tron.error( 'check if user exp, manual error' )
    unless tron_user.experience[tag]?
      throw( 'tag not listed in users exp' )
    unless tron_user.experience[tag] > previous_exp
      throw( 'user expected to gain points for tag' )
  
  #check if a post inserted properly - works
  check_post_insert: ( id, expected_content ) ->
    #post = Posts.findOne( {'_id': id, 'content': expected_content} )
    post = Posts.findOne({'_id': id, 'content': expected_content})
    unless post?
      throw( 'post not found in mongo' )
  
tron.test( new Tests() )