_.extend( Template.session_bar,
  username: ->
    return Session.get('user_id')
)

_.extend( Template.logout_button_top_right,
  events: {
    'click a.logout_top_right': (event) ->
      Meteor.logout()
  }
)