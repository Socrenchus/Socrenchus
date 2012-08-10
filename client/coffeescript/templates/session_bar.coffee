_.extend( Template.session_bar,
  username: ->
    if (Meteor.user())?
      Meteor.user().name
    else
      "You are not logged in."
    
  events: {
    'click .logout_top_right': (event) ->
      Meteor.logout()
  }
)
