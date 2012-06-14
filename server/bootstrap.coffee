Meteor.startup ->
  if Posts.find().count() is 0 
    Instances = [
      {
        id: "metaCrunch"
        admin: "bryan@socrench.us"
        domain: "www.socrench.us"
        }
    ]
    
    users = [
      {
        email: 'test0@example.com'
        experience: {
          'tag': 2
          'tag2': 3
        }
      },
      {
        email: 'test1@example.com'
        experience: {
          'one': 5
        }
      },
      {
        email: 'test2@example.com'
        experience: {
          'two': 7
        }
      }
    ]
    posts = [
      {
        instance_id: 'metaCrunch'
        author_id: 0
        content: 'Hello, I am a post.'
        tags: {
          'one': {
            users: ['user1', 'user2']
            weight:  4
            }
          'two': ['user2']
          'red': ['user1']
          'blue': ['user2']
        }
      },
      {
        instance_id: 'metaCrunch'
        author_id: 2
        content: 'Hi, I\'m another one.'
        tags: {
          'one': {
            users: ['user1', 'user2']
            weight: 2
            }
          'red': ['user1']
        }
      },
      {
        instance_id: 'metaCrunch'
        author_id: 2
        content: 'Me too!!'
        parent_id: 0
      },
      {
        instance_id: 'metaCrunch'
        author_id: 1
        content: 'I\'m a child.'
        parent_id: 0
      }
      {
        instance_id: 'metaCrunch'
        author_id: 0
        content: 'whattsup'
      }
    ]
    timestamp = (new Date()).getTime()
    user_ids = []
    for user in users
      user_ids.push Users.insert(user)
    post_ids = []
    for post in posts
      if 'author_id' of post
        post.author_id = user_ids[post.author_id]
      if 'parent_id' of post
        post.parent_id = post_ids[post.parent_id]
      post_ids.push Posts.insert(post)