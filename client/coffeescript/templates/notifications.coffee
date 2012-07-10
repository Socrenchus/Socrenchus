_.extend( Template.notifications,
  count: -> Notifications.find().fetch().length
  notifications: -> return Notifications.find().fetch()
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

Handlebars.registerHelper('notifs', (context, object) ->
  message = ''
  for notification in context
    message += "<div class='notify-message'>"
    if notification['points'] > 0
      message += '+'
    if notification['points'] != 0
      message += "#{notification['points']} - "
    
    users = notification['other_users'].length
    if users > 1
      message += "#{users} people "
    else if users == 1
      message += "This person "  #TODO: link to user's page
    
    switch notification['kind']
      when 0 then message += "replied to your <a href='/#{notification['post']}'>post</a>."
      when 1 then message += "<span style='background-color: #FFFF00' title='#{notification['tag']}'>Your tag</span> on <a href='/#{notification['post']}'>this post</a> graduated."
      when 2 then message += "tagged your <a href='/#{notification['post']}'>post</a>."
    message += "<br>#{notification['timestamp']}"
    message += "</div>"
  return message
)

$(document).click( ->
  if Session.get('notifications_state', 'open')
    Session.set('notifications_state', 'closed')
)
