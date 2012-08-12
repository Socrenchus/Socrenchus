_.extend( Template.notifications,
  notifications: ->
    groups = {}
    notifs = Notifications.find({},{sort:{timestamp:-1}}).fetch()
    
    #Grouping code
    for doc in notifs
      groups[doc.type + doc.post] ?= []
      groups[doc.type + doc.post].push( doc )
    
    return ( v for k, v of groups )
  
  post_id : -> @[0].post
  
  group_message: ->
    pts = 0
    points = ''
    for notif in @
      pts += notif.points
    
    if pts > 0
      points += '+'
    if pts != 0
      points += "#{Math.round(pts)} - "
    
    first = @[0]
    is_group = @length > 1
    link_text = ''
    message = ''
    #TODO: link to user's page & the relevant post, display tags as alt-text
    #Note: Use <abbr title='alt_text'>This tag</abbr> format
    switch first.type
      when 0
        message += "<i class='icon-comment-alt'></i> "
        message += (if is_group then "#{@length} people " else "Someone ")
        message += "replied to your post."
      when 1
        link_text += "Your tag" + (if is_group then "s" else "")
        message += " on a post graduated."
      when 2
        link_text += (if is_group then "#{@length} tags" else "A tag")
        message += " graduated on your post."
    
    return {points: points, link_text: link_text, message: message, timestamp:first.timestamp}
  
  timestamp: -> 
    timestamp = new Date(@timestamp)
    return {relative: timestamp.relative(), full: timestamp.readable()}
  
  show: -> Session.equals('notifications_state','open')

  events: {
    'click #notification-counter': (event) ->
      if Session.equals('notifications_state', 'open')
        Session.set('notifications_state', 'closed')
      else
        Session.set('notifications_state', 'open')
    'click .notify-message': (event) ->
      if not event.isPropagationStopped()
        window.location ="/p/#{@cur[0].post}"
        event.stopPropagation()
    'click': (event) ->
      event.stopPropagation()
  }
)

$(document).click( ->
  if Session.get('notifications_state', 'open')
    Session.set('notifications_state', 'closed')
)
