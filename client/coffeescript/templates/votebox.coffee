_.extend( Template.votebox,
  voted: -> @my_vote!=null  
  voted_up: -> @my_vote=="up"
  voted_down: -> @my_vote=="down"
  score: -> @vote_weight
  events: {
    "click button[name='up_vote']": (event) ->
      Session.set("voted_#{@_id}",true)
      @my_vote = "up"
      ###
      @votes.up.users.push(Session.get('user_id'))
      Posts.update(@_id, {$set: {votes: @votes}})
      ###
    "click button[name='down_vote']": ->
      Session.set("voted_#{@_id}",true)
      @my_vote = "down"
      ###
      @votes.down.users.push(Session.get('user_id'))
      Posts.update(@_id, {$set: {votes: @votes}})
      ###
  }
)
