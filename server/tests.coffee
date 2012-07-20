class Tests
  #dummy
  try_nothing: ->
    tron.info( 'a dummy try function' )

  
  #check if a tag/user_id exists for a given post
  check_add_tag: (server_post, tag, user_id) ->
      if false
        tron.error 'check_tagged manual fail'
      #check if tag is present for post
      unless server_post.tags[tag]?
        tron.error( 'tag not present in post' )
      #check that the tag object has the user_id in users[]
      unless user_id in server_post.tags[tag].users
        tron.error( 'user not listed for tag.' )
  
  check_if_user_exp: (user_id, tag) ->
    tron_user = Users.findOne( user_id )
    tron.log( 'check_if_user_exp' )
    if false
      tron.error( 'check if user has exp, manual fail' )
    unless tron_user.experience[tag]?
      tron.error( 'tag not listed in users exp' )
    unless tron_user.experience[tag] > 0
      tron.error( 'user has 0 or less points for tag' )
  
tron.test( new Tests() )