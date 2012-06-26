# Very useful helper function to remove array items
Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

class Tron
  constructor: ->
    @timers = []
    
  test: (args...) ->
    u = """

     This simple function will define the way we test Socrenchus. You can do
     things in most of the same ways you did them with the console.

     Call it with your test function like this:

      tron.test( ->
        tron.log( 'this writes to the log' )
        tron.info( 'this is an info message' )
        tron.warn( 'this is a warning' )
        tron.error( 'this is an error' )
      )

    """
    for a in args
      unless typeof a == 'function'
        @warn(usage)
      else
        a()
        
  stopwatch: ( timer_name ) ->
    u = """
    
     This function acts as both console.time and console.timeEnd, just pass it
     a string to start the timer, and the same string to stop it.
    
    """
    unless timer_name?
      @warn(u)
    else unless timer_name in @timers
      @timers.push( timer_name )
      console.time( timer_name )
    else
      r = console.timeEnd( timer_name )
      @timers.remove( timer_name )
      return r

  log:    (args...) -> console.log(args...)
  info:   (args...) -> console.info(args...)
  warn:   (args...) -> console.warn(args...)
  error:  (args...) -> console.error(args...)
  dir:    (args...) -> console.dir(args...)
  trace:  (args...) -> console.trace(args...)
  assert: (args...) -> console.assert(args...)

tron = new Tron()