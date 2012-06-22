_.extend( Template.votebox,
  voted: true
  score: -> @votes.up.weight - @votes.down.weight
  events: {
    #'click button': ->
    #  disable buttons
    "click button[name='upvote']": ->
      @votes.up.users.push(###current user id###)
      @votes.up.weight++
    "click button[name='downvote']": ->
      @votes.down.users.push(###current user id###)
      @votes.down.weight++
  }
)
