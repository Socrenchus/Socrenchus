_.extend( Template.votebox,
  voted: -> @my_vote!=null  
  voted_up: -> @my_vote==true
  voted_down: -> @my_vote==false
  score: -> @vote_weight
  events: {
    "click button[name='up_vote']": (event) ->
      #Session.set("voted_#{@_id}",true)
      @my_vote = true
      ###
      @votes.up.users.push(Session.get('user_id'))
      Posts.update(@_id, {$set: {votes: @votes}})
      ###
    "click button[name='down_vote']": ->
      #Session.set("voted_#{@_id}",false)
      @my_vote = false
      ###
      @votes.down.users.push(Session.get('user_id'))
      Posts.update(@_id, {$set: {votes: @votes}})
      ###
  }
)
