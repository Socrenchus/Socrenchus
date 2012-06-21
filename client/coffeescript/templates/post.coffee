_.extend( Template.post,
  content: -> 
    showdownConverter = new Showdown.converter()
    postContentHtml = showdownConverter.makeHtml(@content)
    return postContentHtml
  identifier: -> @_id
  groupname: -> @group
  events: {
    "click button[name='replySubmit']": (event) ->
      if !event.isImmediatePropagationStopped()
        replyTextBox = event.target.parentNode.getElementsByTagName("textarea")[0]
        event.stopImmediatePropagation()
        replyContent = replyTextBox.value
        console.log("ID of Post you're replying to: ")
        console.log("Reply content: #{replyContent}")
        if(replyContent=="")
          alert('Selected Reply Box is Null!')#debugging why we're selecting the wrong text box.
        else
          replyID = Posts.insert(
            {
              content: replyContent,
              parent_id: @_id,
              instance_id: @instance_id
            }
          )
          console.log("ID of new post: "+replyID)
          replyTextBox.value = '' #clear the textbox for giggles -- should probably do this only if the post succeeds.
  }
  
)

###
# HELPER FUNCTIONS
#  v v v v v v v
###

###
#MakeGroups: Make a list of groups containing posts, for a given set of posts.
#    Incubator group
#    Tag group: group for each graduated tag.  
###
makeGroups = (posts) ->
  groups = {'Incubator': {'posts': []}}
  for post in posts.fetch()
    tagCount = 0
    placed = false #post has not been placed into a group yet.
    for tag of post.tags
      if graduated(tag, post) 
        if groups[tag]? #if there is a group for this tag
          groups[tag].posts.push(post) #add this post to the group's posts
        else
          groups[tag] = {'posts': [post]} #add a tag group with a "posts" field containing this post
        placed = true #this post has been placed
      else if not placed #if the post isn't graduated and hasn't 
        groups['Incubator'].posts.push(post)
        placed = true
      tagCount++
    if tagCount == 0
      groups['Incubator'].posts.push(post)
  groupList = []
  for name,info of groups
    if info.posts.length != 0
      groupList.push({'name':name, 'posts':info.posts})
  return groupList
