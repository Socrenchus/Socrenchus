_.extend( Template.notifications,
  count: -> Session.get('notfs').length
  ntfs: -> return Session.get('notfs')
  show: -> Session.equals('state','open')
  message: -> @message
  events: {
    'click #notification-counter': (event) ->
      if Session.equals('state', 'open')
        Session.set('state', 'closed')
      else
        Session.set('state', 'open')
    'click': (event) ->
      event.stopPropagation()
  }
)

tempNotfs = [{message: 'hi'},{message: 'there'},
      {message: 'friend'},{message: 'how'},
      {message: 'are'},{message: 'you'},
      {message: 'today'}]
      
Session.set('notfs', tempNotfs)

#$(document).click ->
#  if Session.get('state', 'open')
#    Session.set('state', 'closed')
