class GCTests
  #insert new post
  insertpost: (args...) ->
    content = Meteor.uuid()
    #id = Meteor.call('get_user_id')
    Posts.insert({content: content})
    tron.log('TEST: Inserting randomized tag with content:\n', content)

  #insert/update tag in random post
  inserttag: (args...) ->
    if args[0]?
      id = args[0]
    else
      id = Meteor.call('get_user_id')
    tag_text = Meteor.uuid()
    q = {'$set': {}}
    q['$set']["my_tags.#{tag_text}"] = 1
    tron.log('TEST: Inserting randomized tag:\n', q, 'author_id:', id)
    Posts.update({ '_id': id}, q)

  #replying to own post
  reply: (args...) ->
    post = args[0]
    parent = Posts.findOne(_id: post.parent_id)
    if parent._id is post._id
      tron.log 'Replying to own post'
  
  #replying to post already replied to
  # do we have child id's or something?
  
  #reply only after you tag
  havetheytagged: (args...) ->
    post = args[0]
    id = Meteor.call('get_user_id')
    for tag in post.tags
      if id in tag.users
        tron.log('user has tagged this post')
  
gctest = new GCTests()
