class Tron
  constructor: ->
    
  test:   (args...) ->
    usage = """

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

  log:    (args...) -> console.log(args...)
  info:   (args...) -> console.info(args...)
  warn:   (args...) -> console.warn(args...)
  error:  (args...) -> console.error(args...)
  dir:    (args...) -> console.dir(args...)
  time:   (args...) -> console.time(args...)
  trace:  (args...) -> console.trace(args...)
  assert: (args...) -> console.assert(args...)

tron = new Tron()