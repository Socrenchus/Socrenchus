_.extend( Template.conversation,
  show_post: ->
    not Session.equals('showing_post', undefined)
    
  root_post: ->
    posts = []
    cur_post = Session.get('showing_post')
    posts.push(cur_post)
    
    #Get ancestors of selected post
    while cur_post?.parent_id?
      cur_post = Posts.findOne( _id: cur_post.parent_id )
      posts.unshift( cur_post )
      
    #Set up reactive tree structure for post lineage
    for post,i in posts
      Session.set("reply_#{post._id}", posts[i+1]?._id) if post?
    
    #Scroll to the selected post
    Meteor.defer( ->
      post = $('#'+Session.get('showing_post')._id)[0]
      post?.scrollIntoView()
    )
    
    return posts[0]
)
