_.extend( Template.votebox,
  voted: -> Session.get("voted_#{@_id}") || Session.get('user_id') in @votes.up.users || Session.get('user_id') in @votes.down.users
  score: -> @votes.up.users.length - @votes.down.users.length
  events: {
    "click button[name='upvote']": (event) ->
      Session.set("voted_#{@_id}",true)
      @votes.up.users.push(Session.get('user_id'))
      Posts.update(@_id, {$set: {votes: @votes}})
    "click button[name='downvote']": ->
      Session.set("voted_#{@_id}",true)
      @votes.down.users.push(Session.get('user_id'))
      Posts.update(@_id, {$set: {votes: @votes}})
  }
)
