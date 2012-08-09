_.extend( Template.session_bar,
  username: ->
    return Meteor.user().name
    
  events: {
    'click a.logout_top_right': (event) ->
      Meteor.logout()
      window.location = '#'
  }
)