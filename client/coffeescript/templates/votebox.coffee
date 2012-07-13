_.extend( Template.votebox,
  voted: -> not @my_vote?
  voted_up: -> voted && @my_vote
  voted_down: -> voted && not @my_vote
  score: ->
  events: {
    "click button[name='up_vote']": (event) ->
    "click button[name='down_vote']": ->
  }
)
