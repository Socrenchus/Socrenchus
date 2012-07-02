_.extend( Template.votebox,
  voted: ->
    if (@my_vote is undefined)
      return false
    else
      return true
  voted_up: -> @my_vote is true
  voted_down: -> @my_vote is false
  score: -> @votes['up'].count - @votes['down'].count
  events: {
    "click button[name='up_vote']": (event) ->
      Posts.update(@_id, {$set: {my_vote: true}})
      #Session.set("voted_#{@_id}",true)
      #@votes.up.users.push(Session.get('user_id'))
      #Posts.update(@_id, {$set: {votes: @votes}})
    "click button[name='down_vote']": ->
      alert 'push'
      Posts.update(@_id, {$set: {my_vote: false}})
      #Session.set("voted_#{@_id}",true)
      #@votes.down.users.push(Session.get('user_id'))
      #Posts.update(@_id, {$set: {votes: @votes}})
  }
)
