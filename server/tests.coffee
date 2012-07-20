class Tests
  #dummy
  try_nothing: ->
    tron.info( 'a dummy try function' )
  
  check_add_tag: (server_post, tag, user_id) ->
      if false
        tron.error 'check_tagged manual fail'
      #check if tag is present for post
      unless server_post.tags[tag]?
        tron.error( 'tag not present in post' )
      #check that the tag object has the user_id in users[]
      unless user_id in server_post.tags[tag].users
        tron.error( 'user not listed for tag.' )
  
tron.test( new Tests() )