_.extend( Template.votebox,
  voted: -> Session.get("voted_#{@_id}")
  score: -> @votes.up.users.length - @votes.down.users.length
  events: {
    "click button[name='upvote']": ->
      user_id = Session.get('user_id')
      @votes.up.users.push(user_id)
      Session.set("voted_#{@_id}",true)
    "click button[name='downvote']": ->
      user_id = Session.get('user_id')
      @votes.down.users.push(user_id)
      Session.set("voted_#{@_id}",true)
  }
)
