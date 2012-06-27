_.extend( Template.votebox,
  voted: -> (@my_vote==true or @my_vote==false)
  voted_up: -> @my_vote==true
  voted_down: -> @my_vote==false
  weight_diff: -> 
    @votes['up'].weight - @votes['down'].weight
    ###
      votes :{
        'up' : {
          count: 0
          weight: 0
        }
        'down' : {
          count: 0
          weight: 0
        }
      }
    ###

  events: {
    "click button[name='up_vote']": (event) ->
      Posts.update({_id: @_id}, {$set: {my_vote: true}})
    "click button[name='down_vote']": ->
      Posts.update({_id: @_id}, {$set: {my_vote: false}})
  }
)
