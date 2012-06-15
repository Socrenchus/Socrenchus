Meteor.startup ->
  if Posts.find().count() is 0 
    instances = [
      {
        admin_id: 0
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
        instance_id: 0
        author_id: 0
        content: 'Hello, I am a post.'
        tags: {
          'one': {
            users: [1, 2]
            weight:  4
            }
          'two': {
            users: [2]
            weight: 2
            }
          'red': {
            users: [1]
            weight: 1
            }
          'blue': {
            users: [2]
            weight: 4
            }
        }
      },
      {
        instance_id: 0
        author_id: 2
        content: 'Hi, I\'m another one.'
        tags: {
          'one': {
            users: [1, 2]
            weight: 2
            }
          'red': {
            users: [1]
            weight: 3
            }
        }
      },
      {
        instance_id: 0
        author_id: 2
        content: 'Me too!!'
        parent_id: 0
        tags:{}
      },
      {
        instance_id: 0
        author_id: 1
        content: 'I\'m a child.'
        parent_id: 0
        tags:{}
      }
      {
        instance_id: 0
        author_id: 0
        content: 'whattsup'
        tags:{}
      }
    ]
    timestamp = (new Date()).getTime()
    
    user_ids = [] 
    for user in users
      user_ids.push Users.insert(user)
    instance_ids = []
    for instance in instances
      if 'admin_id' of instance
        instance.admin_id = user_ids[instance.admin_id]
      instance_ids.push Instances.insert(instance)
    post_ids = []
    for post in posts
      if 'author_id' of post
        post.author_id = user_ids[post.author_id]
      if 'parent_id' of post
        post.parent_id = post_ids[post.parent_id]
      if 'instance_id' of post
        post.instance_id = instance_ids[post.instance_id]
      if 'tags' of post
        for tag in post.tags
          tagger_ids = []
          for user in post.tag.users
            tagger_ids.push user_ids[user]
          post.tag.users = tagger_ids
      Posts.insert(post)
      
#         for tag in [0..post.tags.length-1]
#           tag_user_ids = []
#           for user in [0..tag.users.length-1]
#             tag_user_ids.push post[tag][user]
#             #tag_user_ids.push user_ids[post[tag][user]]
#           post[tag].users = tag_user_ids
#       Posts.insert(post)