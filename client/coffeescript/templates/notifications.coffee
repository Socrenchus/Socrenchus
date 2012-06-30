_.extend( Template.notifications,
  count: -> Session.get('notifications').length
  notifications: -> return Session.get('notifications')
  show: -> Session.equals('notifications_state','open')
  message: -> @message
  events: {
    'click #notification-counter': (event) ->
      if Session.equals('notifications_state', 'open')
        Session.set('notifications_state', 'closed')
      else
        Session.set('notifications_state', 'open')
    'click': (event) ->
      event.stopPropagation()
  }
)
      
Session.set('notifications', [])

$(document).click( ->
  if Session.get('notifications_state', 'open')
    Session.set('notifications_state', 'closed')
)
