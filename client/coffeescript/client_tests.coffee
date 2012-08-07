class ClientTests
  test_id = ''                                          #the id of the test post
  test_content = 'gen by client side tron tests'        #the content of test post
  
  #insert new post - not tested for client
  try_client_insert_post: ->
    @test_id = Posts.insert(
      'content': @test_content
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
    tron.test( 'check_post_insert', @test_id, @test_content ) 
    #TODO remove the post, this is not allwed by GC.
  
  #try to insert a tag
  try_client_insert_tag: ->
    q = {'$set': {}}
    tag_text = 'gen_by_client_try_insert_tag'
    q['$set']["my_tags.#{tag_text}"] = 1
    Posts.update({ '_id': @test_id}, q)
    #hits check_add_tag on server side.
    #TODO remove tag
  

  #try to update a tag
  try_client_update_tag: ->
    #tron.log 'try_client_update_tag'
    #find a post with tag
    post = Posts.findOne( @test_id )
    #tag it as a different user
      #this should also graduate the tag until the graduation function is updated.
    tag = 'tron'
    q = {'$set': {}}
    q['$set']["my_tags.#{tag}"] = 1
    Posts.update({'_id': post._id}, q)
    #check_add_tag should be hit by this.
    #TODO remove tag at the end.
    #TODO this is not truly using a different user id,
    
  #check if a post inserted properly - works
  check_post_insert: ( id, expected_content ) ->
    post = Posts.findOne({'_id': id, 'content': expected_content})
    unless post?
      throw( 'post not found in mongo' )

    
tron.test( new ClientTests() )