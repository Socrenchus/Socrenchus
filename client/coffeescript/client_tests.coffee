tron.test(
  try_client_insert_post: ->
    test_id = Posts.insert(
      'content': 'tron'
      'parent_id': null
      'instance_id': null
      'tags': {
        'gen_by_try_insert_post': {
          'users': []
          'weight': 0
        }
        'tron_tag': {
          'users': []
          'weight': 0
        }
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
    Posts.remove( test_id )
  
  try_client_insert_tag: ->
    test_id = Posts.insert( 
      'content': 'tron'
      'tags':{
        'tron_tag': {
          'users': [ Users.findOne() ]
          'weight': 0
        }
      }
    )
    q = {'$set': {}}
    tag_text = 'gen_by_client_try_insert_tag'
    q['$set']["my_tags.#{tag_text}"] = 1
    Posts.update({ '_id': test_id}, q)
    tron.test( 'check_tag', test_id, 'tron_tag' )
    Posts.remove( test_id )
    
  try_client_update_tag: ->
    test_id = Posts.insert( 
      'content': 'tron'
      'tags':{
        'tron_tag': {
          'users': [ Users.findOne() ]
          'weight': 0
        }
      }
    )
    post = Posts.findOne( )
    tag = 'tron_tag'
    q = {'$set': {}}
    q['$set']["my_tags.#{tag}"] = 1
    Posts.update({'_id': post._id}, q)
    tron.test( 'check_tag', test_id, 'tron_tag' )
    Posts.remove( test_id )
    
  check_post_insert: ( id ) ->
    post = Posts.findOne( id )
    unless post?
      throw( 'post not found in mongo' )
  
  #check if a tag exists for a post
  check_tag: ( post_id, tag ) ->
    post = Posts.findOne( post_id )
    unless post?
      throw 'post not found'
    unless tag in _.keys( post.tags )
      throw 'tag not found in post'

)