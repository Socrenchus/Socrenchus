_.extend(console,
  warn: (args...) ->
    _console.warn(args...)
  test: (args...) ->
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
)