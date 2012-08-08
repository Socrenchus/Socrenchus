_.extend( Template.conversation,
  show_post: ->
    not Session.equals('showing_post', undefined)
    
  root_post: ->
    cur_post = Session.get('showing_post')
    
    #Carousel implementation
    Session.set('carousel_parent', cur_post)
    carousel_handle = Meteor.setInterval(start_carousel, 3000)
    Session.set('carousel_handle', carousel_handle)
    
    posts = []
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
