_.extend( Template.notifications,
  count: -> Notifications.findOne()?.groups.length
  notifications: -> return Notifications.findOne().groups
  post_id : -> @[0].post
  message: ->
    pts = 0
    points = ''
    for notif in @
      pts += notif.points
    
    if pts > 0
      points += '+'
    if pts != 0
      points += "#{pts} - "
    
    first = @[0]
    is_group = @length > 1
    
    message = ''
    link = ''
    link_text = ''
    #TODO: link to user's page & the relevant post, display tags as alt-text
    #Note: Use <abbr title='alt_text'>This tag</abbr> format
    switch first.type
      when 0
        message += (if is_group then "#{@length} people " else "This person ")
        message += "replied to your post."
      when 1
        link_text += "Your tag" + (if is_group then "s" else "")
        message += " on this post graduated."
        for notif in @
          link += "/#{notif.tag}"
      when 2
        link_text += (if is_group then "These tags" else "This tag")
        message += " graduated on your post."
        for notif in @
          link += "/#{notif.tag}"
    
    return {points: points, link: link, link_text: link_text, message: message}
  
  timestamp: -> 
    timestamp = new Date(@[0].timestamp)
    
    #Get smart timestamp
    timediff = (new Date()).getTime() - timestamp.getTime()
    if timediff < (1000*60) #under one minute ago
      smart = "#{Math.round(timediff / 1000)} seconds ago"
    else if timediff < (1000*60*60) #under one hour ago
      smart = "#{Math.round(timediff / 1000 / 60)} minutes ago"
    else if timediff < (1000*60*60*24) #under one day ago
      smart = "#{Math.round(timediff / 1000 / 60 / 60)} hours ago"
    else if timediff < (1000*60*60*24*7) #under one week ago
      days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
      smart = "on #{days[timestamp.getDay()]}"
    else
      smart = timestamp.toDateString()
    
    #Get full timestamp
    ap = 'am'
    hour = timestamp.getHours()
    ap = 'pm' if hour > 11
    hour = hour - 12 if hour > 12
    hour = 12 if hour == 0
    minutes = timestamp.getMinutes()
    minutes = "0#{minutes}" if minutes < 10
    full = "#{timestamp.toDateString()} at #{hour}:#{minutes}#{ap}"
    return {smart: smart, full: full}
  
  show: -> Session.equals('notifications_state','open')

  events: {
    'click #notification-counter': (event) ->
      if Session.equals('notifications_state', 'open')
        Session.set('notifications_state', 'closed')
      else
        Session.set('notifications_state', 'open')
    'click .notify-message': (event) ->
      if not event.isPropagationStopped()
        window.location ="/#{@[0].post}"
        event.stopPropagation()
    'click': (event) ->
      event.stopPropagation()
  }
)

$(document).click( ->
  if Session.get('notifications_state', 'open')
    Session.set('notifications_state', 'closed')
)
