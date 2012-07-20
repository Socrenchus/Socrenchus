class Tests
  #dummy
  try_nothing: ->
    a = 0
  
  check_tagged: (server_post, tag, user_id) ->
      #check if tag is present for post
      unless user_id in server_post.tags[tag].users
        tron.error( 'add_tag post check, user not added to list.' )
      #check that the tag object has the user_id in users[]
  
tron.test( new Tests() )