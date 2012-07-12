class GCTests
  insertpost: (args...) ->
    tron.log('Post to be inserted as sent by user:\n', args)
    if args[0].author_id? and args[0].author_id isnt ''
      tron.error('User is trying to specify a author_id...')
      tron.log( '  user-specified author_id:', args[0].author_id,
              '\n          actual author_id:', args[1]
      )
    
gctest = new GCTests()
