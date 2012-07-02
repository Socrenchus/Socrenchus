_.extend( Template.session_bar,
  username: ->
    if (Session.get('branch') is 'TEST_BRANCH')
      return "You're a winner!!"
    else
      return Session.get('user_id')
)