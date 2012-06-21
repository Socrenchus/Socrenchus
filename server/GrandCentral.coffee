###
trun _debug off for deployment
all db communications go through this class
this file overrides default meteor methods that handle the same with mongo.
###

_debug = true

class StationMaster
  ###
    list of error codes:
    0 = shits ok
    1 = warning
    2 = error
  ###

  #not debug mode unless specified in constructor
  debug_mode = false
  constructor: (arg)->
    debug_mode = arg
  
  #the validation functions and sanity checks
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
    #removing posts is not allowed for now
    return 2

  valid_instance_insert: (args...) ->
    return 0
    
  valid_instance_update: (args...) ->
    return 0
  
  valid_instance_remove: (args...) ->
    return 0

class GrandCentral
  error_list = []
  warning_list = []
  sm = new StationMaster (_debug)
  
  constructor: (@collection, @method) ->
    @default = Meteor.default_server.method_handlers["/#{@collection}/#{@method}"]
    Meteor.default_server.method_handlers["/#{@collection}/#{@method}"] = @dispatch
  dispatch: (args...) =>
    {
      users: {
        insert: (args...) =>
          msg = sm.valid_user_insert(args...)
          if (msg is 0)
            console.log 'valid user insert request'
          else if (msg is 1)
            warning_list.push 'invalid user insert request'
          else if (msg is 2)
            error_list.push 'invalid user insert request'
        update: (args...) =>
          msg = sm.valid_user_update(args...)
          if (msg is 0)
            console.log 'valid user update request'
          else if (msg is 1)
            warning_list.push 'invalid user update request'
          else if (msg is 2)
            error_list.push 'invalid user update request'
        remove: (args...) =>
          msg = sm.valid_user_remove(args...)
          if (msg is 0)
            console.log 'valid user remove request'
          else if (msg is 1)
            warning_list.push 'invalid user remove request'
          else if (msg is 2)
            error_list.push 'invalid user remove request'
      }
      posts: {
        insert: (args...) =>
          #add author_id to args
          args[0].author_id = Session.get 'user_id'
          #check for validity of request
          msg = sm.valid_user_insert(args...)
          if (msg is 0)
            console.log 'valid user insert request'
          else if (msg is 1)
            warning_list.push 'invalid user insert request'
          else if (msg is 2)
            error_list.push 'invalid user insert request'
          #add experience points
        update: (args...) => 
        remove: (args...) =>
          msg = sm.valid_post_remove()
          if (msg is 0)
            console.log 'valid post remove request'
          else if (msg is 1)
            warning_list.push 'removing a post is not socrench, allowed for debug mode'
          else if (msg is 2)
            error_list.push 'post remove requests not entertained'
          
      }
      instances: {
        insert: (args...) =>
        update: (args...) =>
        remove: (args...) =>
      }
    }[@collection][@method](args...)
    
    #if no errors/warnings or debug mode, execute
    #also call logic functions for experience etc.
    if  _debug || (error_list.length is 0 && warning_list.length is 0)
      @default.apply(@, args)
    else
      if error_list.length>0
        console.log 'Grand Central errors encountered:'
        for error in error_list
          console.log error
      if warning_list.length>0
        console.log 'warnings encountered:'
        for warning in warning_list
          console.log warning 

Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      gc = new GrandCentral(collection, method)
)