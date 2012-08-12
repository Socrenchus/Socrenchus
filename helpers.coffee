_.extend(Array::,
  remove: (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

  clone: -> this[..]
)

_.extend(Date::,
  days_of_week: [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ]

  relative: ->
    #Get smart timestamp
    time_diff = (new Date()).getTime() - @getTime()
    time_dict =
      minute:
        size: 60000
        to_string: => "#{Math.round(time_diff / 1000)} seconds ago"
      hour:
        size: 3600000
        to_string: => "#{Math.round(time_diff / 60000)} minutes ago"
      day:
        size: 86400000
        to_string: => "#{Math.round(time_diff / 3600000)} hours ago"
      week:
        size: 604800000
        to_string: => "on #{@days_of_week[@getDay()]}"
        
    for k, v of time_dict
      if time_diff < v.size
        return v.to_string()
    
    return @toDateString()

  readable: ->
    #Get full readable timestamp
    ap = 'am'
    hour = @getHours()
    ap = 'pm' if hour > 11
    hour = hour - 12 if hour > 12
    hour = 12 if hour == 0
    minutes = @getMinutes()
    minutes = "0#{minutes}" if minutes < 10
    full = "#{@toDateString()} at #{hour}:#{minutes}#{ap}"
    return full
)