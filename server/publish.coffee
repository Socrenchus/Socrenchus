Users = Meteor.users
Posts = new Meteor.Collection( "posts" )
Instances = new Meteor.Collection( "instances" )
Notifications = new Meteor.Collection("notifications")


Meteor.publish("my_notifs", ->
  user_id = @userId()
  if user_id?
    return Notifications.find( user: user_id )
)

Meteor.publish( "current_posts", ( post_id, list ) ->
  #list indicates the posts in the path to leaf have been clicked
  #by the user, 
  user_id = @userId()
  if user_id?
    handle = null
    q = null
    ids = []
    path_to_root = []
    first_action = (item, idx) =>
      #gather ids of posts leading to root
      path_to_root.push( item._id )
      this_post = item._id
      while Posts.findOne( this_post )?.parent_id?
        this_post = Posts.findOne( this_post ).parent_id
        if this_post not in ids
          path_to_root.push( this_post )
      for i in path_to_root
        if i not in ids
          ids.push( i )
      
      # check if any posts were authered by user in the path to root
      authored = []
      for pid in path_to_root
        p = Posts.findOne( pid )
        if user_id is p.author_id
          authored.push( p._id )
              

      console.log '#if authored, publish path to leaf'
      #if authored, publish path to leaf
      path_to_leaf = []
      if authored.length > 0
        cur_post = authored[0]
        next_child = ''
        done = false
        while not done
          children = Posts.find( {'parent_id': cur_post} ).fetch()
          if children?
            for child in children
              if list?
                if child in list
                  next_child = child
            if next_child?
              path_to_leaf.push( next_child )
              cur_post = next_child
            else
              path_to_leaf.push( children[0] )
              cur_post = children[0]
          else
            done = true
      console.log 'authored:', authored
      console.log 'path_to_leaf', path_to_leaf
      
      #add path_to_leaf to ids, also find if more posts are authored
      console.log path_to_leaf
      for i in path_to_leaf
        if Posts.findOne( i ).author_id is user_id
          authored.push( i )
        if i not in ids
          ids.push( i )
      
      #add all siblings of authored posts
      for i in authored
        parent = Posts.findOne( i.parent_id )._id
        siblings = Posts.find( {'parent_id': parent} )
        for s in siblings
          if s not in ids
            ids.push( s )
            
      # query for posts in ids
      q = Posts.find( {'_id': { '$in': ids } } )
      
      if handle?
        handle.stop()

      action = (doc, idx) =>
        client_post = new ClientPost( doc, user_id )
        @set("posts", client_post._id, client_post)
        @flush()
      
      handle = q.observe(
        added: action
        changed: action
      )
      
    #Posts.find( author_id: user_id ).observe(
    Posts.find( post_id ).observe(
      added: first_action
      changed: first_action
    )
    
    @onStop( =>
      if q?
        handle.stop()
        q.rewind()
        posts = q.fetch()
        for post in posts
          fields = (key for key of ClientPost)
          @unset( "my_posts", post._id, fields )
        @flush()
    )
)