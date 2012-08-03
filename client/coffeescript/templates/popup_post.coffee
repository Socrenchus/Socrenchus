_.extend( Template.popup_post,
  show_post: ->
    not Session.equals('showing_post', undefined)
    
  root_post: ->
    posts = []
    cur_post = Session.get('showing_post')
    
    Session.set('carousel_parent', cur_post)
    
    func = ->
      parent = Session.get('carousel_parent')
      cur_reply = Session.get("reply_#{parent._id}")
      if cur_reply?
        console.log('TICK')
        all_replies = Posts.find( parent_id: parent._id ).fetch()
        idx = (all_replies.indexOf(cur_reply) + 1) % all_replies.length
        console.log(idx, all_replies[idx])
        Session.set("reply_#{parent._id}", all_replies[idx])
    
    Meteor.setInterval(func, 3000)
    
    
    posts.push(cur_post)
    
    #Get ancestors of selected post
    while cur_post?.parent_id?
      cur_post = Posts.findOne( _id: cur_post.parent_id )
      posts.unshift( cur_post )
      
    #Set up reactive tree structure for post lineage
    for post,i in posts
      Session.set("reply_#{post._id}", posts[i+1]?._id) if post?
    
    return posts[0]
)
