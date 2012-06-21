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
  verify_user_insert: (args...) ->
     return 0
    
  verify_user_update: (args...) ->
    return 0
  
  verify_user_remove: (args...) ->
    return 0
    
  verify_post_insert: (args...) ->
    return 0
    
  verify_post_update: (args...) ->
    #inserting a post also directs here.
    #upvoting or downvoting 
    return 0
  
  verify_post_remove: (args...) ->
    #removing posts is not allowed for now
    return 2

  verify_instance_insert: (args...) ->
    return 0
    
  verify_instance_update: (args...) ->
    return 0
  
  verify_instance_remove: (args...) ->
    #removing an instance not allowed
    return 2

  ###
  the logic methods go below here
  ###
   
  post_update_logic: (args...) ->
    console.log args
    #when someone inserts a post, they gain no points
    #a user can gain experience by adding tags
    if args.indexOf("tags:") > 0
      user_id = args[0].author_id
      console.log (args)
      #Meteor.default_server.method_handlers['/user/update']("{_id: #{user_id}}, {experience: (  
    
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
          msg = sm.verify_user_insert(args...)
          if (msg is 0)
            #request verified, execute logic
            
          else if (msg is 1)
            warning_list.push 'invalid user insert request'
          else if (msg is 2)
            error_list.push 'invalid user insert request'
        update: (args...) =>
          msg = sm.verify_user_update(args...)
          if (msg is 0)
            #request verified, execute logic
            
          else if (msg is 1)
            warning_list.push 'invalid user update request'
          else if (msg is 2)
            error_list.push 'invalid user update request'
        remove: (args...) =>
          msg = sm.verify_user_remove(args...)
          if (msg is 0)
            #request verified, execute logic
          else if (msg is 1)
            warning_list.push 'invalid user remove request'
          else if (msg is 2)
            error_list.push 'invalid user remove request'
      }
      posts: {
        insert: (args...) =>
          #add author_id to args
          args[0].author_id = Session.get 'user_id'
          msg = sm.verify_post_insert(args...)
          if (msg is 0)
            #request verified, execute logic
            
          else if (msg is 1)
            warning_list.push 'invalid post insert request'
          else if (msg is 2)
            error_list.push 'invalid post insert request'
        update: (args...) =>
          msg = sm.verify_post_update(args...)
          if (msg is 0)
            #request verified, execute logic
            sm.post_update_logic (args)
          else if (msg is 1)
            warning_list.push 'invalid post update request'
          else if (msg is 2)
            error_list.push 'invalid post update request'
        remove: (args...) =>
          msg = sm.verify_post_remove()
          if (msg is 0)
            #request verified, execute logic
          else if (msg is 1)
            warning_list.push 'removing a post is not socrench, allowed for debug mode'
          else if (msg is 2)
            error_list.push 'post remove requests not entertained'
          
      }
      instances: {
        insert: (args...) =>
          msg = sm.verify_instance_insert(args...)
          if (msg is 0)
            #request verified, execute logic
            
          else if (msg is 1)
            warning_list.push 'invalid instance insert request'
          else if (msg is 2)
            error_list.push 'invalid instance insert request'
        update: (args...) =>
          msg = sm.verify_instance_update(args...)
          if (msg is 0)
            #request verified, execute logic
            
          else if (msg is 1)
            warning_list.push 'invalid instance update request'
          else if (msg is 2)
            error_list.push 'invalid instance update request'
        remove: (args...) =>
          msg = sm.verify_instance_remove()
          if (msg is 0)
            #request verified, execute logic
          else if (msg is 1)
            warning_list.push 'warning, removing an instance'
          else if (msg is 2)
            error_list.push 'instance remove requests not entertained'
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