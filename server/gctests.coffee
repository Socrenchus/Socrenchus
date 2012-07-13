class GCTests
  insert_post: (args...) ->
    tron.log('Post to be inserted as sent by user:\n', args)
    if args[0].author_id? and args[0].author_id isnt ''
      tron.error('User is trying to specify a author_id...')
      tron.log( '  user-specified author_id:', args[0].author_id,
              '\n          actual author_id:', args[1]
      )
  run: ( test ) ->
    tests =
      insert_test_tag: ->
        new_tag = Meteor.uuid()
        Posts.update({ _id: Posts.findOne()._id}, {$set: {'my_tags': new_tag}})
    unless test?
      tests[k]() for k of tests
    else
      tests[test]    
  #to call: gctest.run("insert_test_tag")  
  
gctest = new GCTests()
