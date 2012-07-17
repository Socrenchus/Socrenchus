class Tests
  #insert new post - works
  try_insert_post: ->
    content = Meteor.uuid()
    Posts.insert({content: content})
    tron.log('Inserting randomized post with content:\n', content)

  #insert/update tag in random post
  try_insert_tag: (id) ->
    if !id?
      id = Meteor.call('get_user_id')
    tag_text = Meteor.uuid()
    q = {'$set': {}}
    q['$set']["my_tags.#{tag_text}"] = 1
    tron.log('Inserting randomized tag:\n', q, '\n...with author_id:', id)
    Posts.update({ '_id': id}, q)

  #replying to own post - works
  #args: post to be inserted
  check_reply: (post) ->
    parent = Posts.findOne(_id: post.parent_id)
    if parent.author_id is post.author_id
      tron.log('Replying to own post')
  
  #Check if user has already replied to this parent - works
  #args: new_reply: post to be inserted
  check_parent: (new_reply) ->
    for post in Posts.find({parent_id: new_reply.parent_id }).fetch()
      if post.author_id is new_reply.author_id
        tron.log('User has already replied to this post')
  
  #reply only after you tag - works
  #args: post to be inserted
  check_tagging: (post) ->
    parent = Posts.findOne(_id: post.parent_id)
    for tag of parent.tags
      if post.author_id in parent.tags["#{tag}"].users
        tron.log('user has tagged this post')
      else
        tron.log('user has not tagged')
  
  #check if tag update is of proper format
  #args: modifier to be inserted - client schema {$set:{my_tags:...}}
  check_tag_quality: (post_update) ->
    if _.isString(post_update['$set']['my_tags'])
      tron.error('Tag update sent as string, not object')
  
  
  
tron.test( new Tests() )
