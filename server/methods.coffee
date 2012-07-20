Meteor.methods(
  get_user_id: ->
    if Meteor.accounts?
      return @userId()
    else
      #if auth packages do not exist, return the first id you can find.
      return Users.findOne({})._id
  
  get_post_by_id: (post_id) ->
    return Posts.findOne(post_id)
    
  update_server_tron: ( client_tron, fn, args ) ->
    tron.announce = client_tron.announce
    console[fn](args)
    
)
  
Meteor.startup( ->
  tron.subscribe( ( fn, args ) ->
      Meteor.call( 'update_client_tron', tron, fn, args )
  )
)