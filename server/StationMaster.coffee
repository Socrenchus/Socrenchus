###
a class to have all the server side logic
will be called by GrandCentral
- methods shall return 0 for valid, 1 for warning and 2 for error
- requests that return warnings are still allowed in debug mode

TODO: return a number followed by a message
      add sanity checks

###
_debug = false

class StationMaster
  constructor: (debug_mode) ->
    @_debug = debug_mode
    
    
  valid_user_insert: (args...) ->
    return 0
    
  valid_user_update: (args...) ->
    return 0
  
  valid_user_remove: (args...) ->
    return 0
    
  valid_post_insert: (args...) ->
    return 0
    
  valid_post_update: (args...) ->
    return 0
  
  valid_post_remove: (args...) ->
    return 0

  valid_instance_insert: (args...) ->
    return 0
    
  valid_instance_update: (args...) ->
    return 0
  
  valid_instance_remove: (args...) ->
    return 0