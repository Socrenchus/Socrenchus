_.extend( Template.notifications,
  count: -> Session.get('notes').length
  notes: -> return Session.get('notes')
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

tempNotes = [{message: 'hi'},{message: 'there'},
      {message: 'friend'},{message: 'how'},
      {message: 'are'},{message: 'you'},
      {message: 'today'}]
      
Session.set('notes', tempNotes)

#$(document).click ->
#  if Session.get('state', 'open')
#    Session.set('state', 'closed')
