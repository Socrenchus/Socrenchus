_.extend( Template.session_bar,
  username: ->
    return Session.get('user_id')
)