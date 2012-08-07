
#test_id = ''
#test_content = 'gen by client side tron tests'

tron.test(
  try_client_insert_post: ->
    test_id = Posts.insert(
      'content': 'tron'
      'parent_id': null
      'instance_id': null
      'tags': {
        'gen_by_try_insert_post': 1
        'tron': 0
        }
      'votes': {
        'up': {
          'users': []
          'weight': 0
        }
        'down': {
          'users': []
          'weight': 0
        }
      }
    )
    tron.test( 'check_post_insert', test_id )
  
  try_client_insert_tag: ->
    q = {'$set': {}}
    tag_text = 'gen_by_client_try_insert_tag'
    q['$set']["my_tags.#{tag_text}"] = 1
    Posts.update({ '_id': @test_id}, q)
  
  ###
  #this try will fail unless debug is set to true on GrandCentral.coffee
  try_client_remove_post: ->
    Posts.remove( @post_id )
    tron.test( 'check_post_remove', @post_id )
  ###
  
  try_client_update_tag: ->
    post = Posts.findOne( )
    tag = 'tron'
    q = {'$set': {}}
    q['$set']["my_tags.#{tag}"] = 1
    Posts.update({'_id': post._id}, q)
    
  check_post_insert: ( id ) ->
    post = Posts.findOne( id )
    unless post?
      throw( 'post not found in mongo' )

  check_post_remove: ( post_id ) ->
    if Posts.findOne( post_id )?
      throw 'post not removed, make sure debug is on in GrandCentral.coffee'
    
)