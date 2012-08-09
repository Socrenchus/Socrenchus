Meteor.startup( ->
  if Posts.find().count() is 0
    notifs = [
      {
        user: 'user_id' #id
        type: 0 # 0 || 1 || 2
        post: 'post_id' #id
        other_user: 'i_replied' #id
        points: 0 #int
        tag: '' #string
        timestamp: new Date(2012, 6, 15, 5) #Date object
      },
      {
        user: 'user_id' #id
        type: 1 # 0 || 1 || 2
        post: 'post_id' #id
        other_user: '' #id
        points: 1 #int
        tag: 'my_tag' #string
        timestamp: new Date() #Date object
      },
      {
        user: 'user_id' #id
        type: 2 # 0 || 1 || 2
        post: 'post_id' #id
        other_user: '' #id
        points: 1 #int
        tag: 'tag_on_my_post1' #string
        timestamp: new Date() #Date object
      },
      {
        user: 'user_id' #id
        type: 2 # 0 || 1 || 2
        post: 'post_id2' #id
        other_user: '' #id
        points: 1 #int
        tag: 'tag_on_my_post' #string
        timestamp: new Date() #Date object
      },
      {
        user: 'user_id' #id
        type: 2 # 0 || 1 || 2
        post: 'post_id' #id
        other_user: '' #id
        points: 1 #int
        tag: 'tag_on_my_post2' #string
        timestamp: new Date() #Date object
      }
    ]
    for notif in notifs
      Notifications.insert(notif)
    instances = [
      {
        admin_id: 0
        domain: "socrench.us"
        }
    ]
    
    users = [
      {
        email: 'test0@localhost'
        experience: {
          'tag': 2
          'tag2': 3
          'one' : 4
          'two' : 1
          'red': 2
          'blue': 1
        }
      },
      {
        email: 'test1@localhost'
        experience: {
          'one': 3
          'two': 3
        }
      },
      {
        email: 'test2@localhost'
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
        suggestions: [
          'tag', 'tron', 'bootstrap', 'stuff'
        ]
        votes: {
          'up': {
            users: [1, 2]
            weight:  4
          }
          'down': {
            users: [2]
            weight: 2
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
        votes: {
          'up': {
            users: [0, 2]
            weight:  4
          }
          'down': {
            users: [2]
            weight: 2
          }
        }
      },
      {
        instance_id: 0
        author_id: 2
        content: 'Me too!!'
        parent_id: 0
        tags:{
          'one': {
            users:[1,2]
            weight: 1
          }
        }
        votes:{
            'up': {
              users: []
              weight: 0
            }
            'down': {
              users: []
              weight: 0
            }
        }
      },
      {
        instance_id: 0
        author_id: 1
        content: 'I\'m a child.'
        parent_id: 0
        tags:{
          'one': {
            users: [1,2]
            weight: 4
          }
          'two': {
            users: [1,2]
            weight:2
          }
        }
        votes:{
            'up': {
              users: []
              weight: 0
            }
            'down': {
              users: []
              weight: 0
            }
        }
      },
      {
        instance_id: 0
        author_id: 1
        content: 'I\'m a child\'s child.'
        parent_id: 4
        tags:{}
        votes:{
            'up': {
              users: []
              weight: 0
            }
            'down': {
              users: []
              weight: 0
            }
        }
      },
      {
        instance_id: 0
        author_id: 1
        content: 'I\'m a child\'s child\'s child.'
        parent_id: 5
        tags:{}
        votes:{
            'up': {
              users: []
              weight: 0
            }
            'down': {
              users: []
              weight: 0
            }
        }
      },
      {
        instance_id: 0
        author_id: 0
        content: 'whattsup'
        tags:{}
        votes:{
            'up': {
              users: []
              weight: 0
            }
            'down': {
              users: []
              weight: 0
            }
        }
      }
    ]
    timestamp = (new Date()).getTime()
    
    user_ids = []
    for user in users
      user_ids.push(Users.insert(user))
    instance_ids = []
    for instance in instances
      if instance.admin_id?
        instance.admin_id = user_ids[instance.admin_id]
      instance_ids.push(Instances.insert(instance))
    post_ids = []
    for post in posts
      id_maps =
        author_id: -> post.author_id = user_ids[post.author_id]
        parent_id: -> post.parent_id = post_ids[post.parent_id]
        instance_id: -> post.instance_id = instance_ids[post.instance_id]
        tags: ->
          for tag, tag_dict of post.tags
            for user, i in tag_dict.users
              post.tags[tag].users[i] = user_ids[user]

      for key of post
        id_maps[key]?()

      post_ids.push(Posts.insert(post))
)
