_.extend( Template.votebox,
  #voted: ->
    #Session.get('user_id') in @votes?.up.users ||
    #Session.get('user_id') in @votes?.down.users
  voted: ->
    not @my_vote is undefined
  #voted_up: -> Session.get('user_id') in @votes?.up.users
  voted_up: -> 
    if (voted)
      @my_vote
    else
      false
  #voted_down: -> Session.get('user_id') in @votes?.down.users
  voted_down: -> 
    if (voted)
      not @my_vote
    else
      false
  score: -> @votes?.up.users.length - @votes?.down.users.length
  events: {
    "click button[name='up_vote']": (event) ->
      @votes?.up.users.push(Session.get('user_id'))
      Posts.update(@_id, {$set: {votes: @votes}})
    "click button[name='down_vote']": ->
      @votes?.down.users.push(Session.get('user_id'))
      Posts.update(@_id, {$set: {votes: @votes}})
  }
)
