_.extend( Template.votebox,
  voted: -> Session.get("voted_#{@_id}")
  score: -> @votes.up.weight - @votes.down.weight
  events: {
    "click button[name='upvote']": ->
      author_id = 0 #How do we get the current user's id?
      @votes.up.users.push(author_id)
      @votes.up.weight++
      Session.set("voted_#{@_id}",true)
    "click button[name='downvote']": ->
      author_id = 0 #Same problem here
      @votes.down.users.push(author_id)
      @votes.down.weight++
      Session.set("voted_#{@_id}",true)
  }
)
