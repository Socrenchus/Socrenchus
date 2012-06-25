###
 
 This simple override will define the way we test Socrenchus.

 Call it like this:

  console.debug( -> 
    console.log( 'this writes to the log' )
    console.info( 'this is an info message' )
    console.warn( 'this is a warning' )
    console.error( 'this is an error' )
  )
  
###
console.debug = (args...) ->
  for a in args
    unless typeof a == 'function'
      console.error('You need to pass a function that can throw its own errors to debug.')
    else
      a()