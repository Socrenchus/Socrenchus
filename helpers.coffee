###
Remove an item e from an array.
###
Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

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