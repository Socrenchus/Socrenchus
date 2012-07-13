_.extend( Template.notifications,
  count: -> Notifications.find().fetch().length
  notifications: -> return Notifications.find().fetch().posts
  message: ->
    message = ''
    if @points > 0
      message += '+'
    if @points != 0
      message += "#{@points} - "
    
    switch @type
      when 0
        users = @other_users.length
        if users > 1
          message += "#{users} people "
        else
          message += "This person "  #TODO: link to user's page
        message += "replied to your <a href='/#{@post}'>post</a>."
      when 1
        message += "<span style='background-color: #FFFF00' title='#{@tag}'>"
        message += "Your tag</span> on <a href='/#{@post}'>this post</a>"
        message += " graduated."
      when 2
        message += "<span style='background-color: #FFFF00' title='#{@tag}'>"
        message += "This tag</span> graduated on your "
        message += "<a href='/#{@post}'>post</a>."
    message += "<br>#{@timestamp}"  #TODO: change to 'x hours ago' format
    return new Handlebars.SafeString(message)
  
  show: -> Session.equals('notifications_state','open')

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

$(document).click( ->
  if Session.get('notifications_state', 'open')
    Session.set('notifications_state', 'closed')
)
