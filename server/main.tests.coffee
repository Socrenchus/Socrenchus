tron.test(
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
)
