class Tron
  constructor: ->
    
  test:   (args...) ->
    usage = """

     This simple function will define the way we test Socrenchus.

     Call it with your test function like this:

      console.test( ->
        console.log( 'this writes to the log' )
        console.info( 'this is an info message' )
        console.warn( 'this is a warning' )
        console.error( 'this is an error' )
      )

    """
    for a in args
      unless typeof a == 'function'
        console.warn(usage)
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