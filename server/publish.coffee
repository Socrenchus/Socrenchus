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
              

      #if authored, publish path to leaf
      path_to_leaf = []
      path_to_leaf.push( item._id )
      if authored.length > 0
        cur_post_id = authored[0]
        next_child_id = null
        done = false
        while not done
          children = Posts.find( {'parent_id': cur_post_id} ).fetch()
          if children.length > 0
            for child in children
              if list?
                if child._id in list
                  next_child_id = child._id
            if next_child_id?
              path_to_leaf.push( next_child_id )
              cur_post_id = next_child_id
            else
              path_to_leaf.push( children[0]._id )
              cur_post_id = children[0]._id
          else
            done = true

      
      #add path_to_leaf to ids, also find if more posts are authored
      for i in path_to_leaf
        if Posts.findOne( i )?.author_id is user_id
          authored.push( i )
        if i not in ids
          ids.push( i )
      
      #add all siblings of authored posts
      for i in authored
        parent = Posts.findOne( i.parent_id )?._id
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