Meteor.startup ->
  if Posts.find().count() is 0
    user_id = Users.insert(email: 'test@example.com')
    data = [
      {
        author_id: user_id,
        content: "Hello, I am a post."
      },
      {
        author_id: user_id,
        content: "Hi, I'm another one."
      },
      {
        author_id: user_id,
        content: "Me tooo!!"
      },
      {
        author_id: user_id,
        content: "I'm a child."
        parent_id: 0 
      }
    ]
    timestamp = (new Date()).getTime()
    i = 0
    post_ids = []
    while i < data.length
      d = data[i]
      if 'parent_id' of d
        d.parent_id = post_ids[d.parent_id]
      post_ids.push Posts.insert(d)
      Tags.insert(name: ',assignment', post_id: post_ids[i], user_id: user_id)
      i++