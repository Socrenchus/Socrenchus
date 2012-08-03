###
Remove an item e from an array.
###
Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

###
Clone an array
###
Array::clone = -> this[..]

###
Pass a string 'trigger' where the callback should go and this
should wait for the callback and returning its arguments.
###
Function::wait = (args...) ->
  error = true
  result = undefined
  f = (args...) -> result = args
  for a, i in args
    if a is 'trigger'
      args[i] = f
      error = false
  return if error
  @(args...)
  while not result? then
  return result
  
Date::smart = ->
  #Get smart timestamp
  timediff = (new Date()).getTime() - this.getTime()
  if timediff < (1000*60) #under one minute ago
    smart = "#{Math.round(timediff / 1000)} seconds ago"
  else if timediff < (1000*60*60) #under one hour ago
    smart = "#{Math.round(timediff / 1000 / 60)} minutes ago"
  else if timediff < (1000*60*60*24) #under one day ago
    smart = "#{Math.round(timediff / 1000 / 60 / 60)} hours ago"
  else if timediff < (1000*60*60*24*7) #under one week ago
    days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    smart = "on #{days[this.getDay()]}"
  else
    smart = this.toDateString()
  return smart

Date::readable = ->
  #Get full readable timestamp
  ap = 'am'
  hour = this.getHours()
  ap = 'pm' if hour > 11
  hour = hour - 12 if hour > 12
  hour = 12 if hour == 0
  minutes = this.getMinutes()
  minutes = "0#{minutes}" if minutes < 10
  full = "#{this.toDateString()} at #{hour}:#{minutes}#{ap}"
  return full
