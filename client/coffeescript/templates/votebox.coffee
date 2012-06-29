_.extend( Template.votebox,
  voted: ->
    if (@my_vote is undefined)
      return false
    else
      return @my_vote
  voted_up: -> @my_vote
  voted_down: -> not @my_vote
  score: -> @votes['up'].count - @votes['down'].count
  events: {
    "click button[name='up_vote']": (event) ->
      Session.set("voted_#{@_id}",true)
      #@votes.up.users.push(Session.get('user_id'))
      Posts.update(@_id, {$set: {votes: @votes}})
    "click button[name='down_vote']": ->
      #Session.set("voted_#{@_id}",true)
      @votes.down.users.push(Session.get('user_id'))
      Posts.update(@_id, {$set: {votes: @votes}})
  }
)
