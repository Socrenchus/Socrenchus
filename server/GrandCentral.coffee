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
  
  #a list of allowed mongo modifiers, all update reauests need to use one of these.
  mongo_modifiers_list = ['$inc', '$set', '$push', '$pushAll', '$addToSet', '$each', '$rename' ]
  #not debug mode unless specified in constructor
  debug_mode = false
  constructor: (arg)->
    debug_mode = arg
  
  #the validation functions and sanity checks
  verify_user_insert: (selector, options) ->
     return 0
    
  verify_user_update: (selector, mutator, options) ->
    return 0
  
  verify_user_remove: (selector) ->
    return 0
    
  verify_post_insert: (selector, options) ->
    return_code = 0
    # make sure the content is blank
    if ( not 'content' in args[0])
      console.log 'no content field provided'
    if (args[0].content is '')
      console.log 'no content provided'
      return_code = 2
    return return_code
    
  verify_post_update: (selector, mutator, options) ->
    #updating post content also directs here.
    #upvoting or downvoting also directs here
    return 0
  
  verify_post_remove: (selector) ->
    #removing posts is not allowed for now
    return 2

  verify_instance_insert: (selector, options) ->
    return 0
    
  verify_instance_update: (selector, mutator, options) ->
    return 0
  
  verify_instance_remove: (selector) ->
    #removing an instance is not allowed
    return 2

  ###
  the logic methods go below here
  ###
   
  post_update_logic: (selector, mutator, options) ->
    #when someone inserts a post, they gain no points
    #a user can gain experience by adding tags (for that tag)
    tagger_id = args[0].author_id
    tags = args[1].tags
    #console.log 'authorID: '+tagger_id
    #console.log 'tags: '+tags
    post_object = Posts.find({_id: tagger_id})
    console.log post_object.tags
    
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
        insert: (selector, options) =>
          msg = sm.verify_user_insert(args...)
          if (msg is 0)
            #request verified, execute logic
            
          else if (msg is 1)
            warning_list.push 'invalid user insert request'
          else if (msg is 2)
            error_list.push 'invalid user insert request'
        update: (selector, mutator, options) =>
          msg = sm.verify_user_update(args...)
          if (msg is 0)
            #request verified, execute logic
            
          else if (msg is 1)
            warning_list.push 'invalid user update request'
          else if (msg is 2)
            error_list.push 'invalid user update request'
        remove: (selector) =>
          msg = sm.verify_user_remove(args...)
          if (msg is 0)
            #request verified, execute logic
          else if (msg is 1)
            warning_list.push 'invalid user remove request'
          else if (msg is 2)
            error_list.push 'invalid user remove request'
      }
      posts: {
        insert: (selector, options) =>
          #add author_id to args
          args[0].author_id = Session.get 'user_id'
          msg = sm.verify_post_insert(args...)
          if (msg is 0)
            #request verified, execute logic
            
          else if (msg is 1)
            warning_list.push 'invalid post insert request'
          else if (msg is 2)
            error_list.push 'invalid post insert request'
        update: (selector, mutator, options) =>
          args[0].author_id = Session.get 'user_id'
          msg = sm.verify_post_update(args...)
          if (msg is 0)
            #request verified, execute logic
            sm.post_update_logic (args)
          else if (msg is 1)
            warning_list.push 'invalid post update request'
          else if (msg is 2)
            error_list.push 'invalid post update request'
        remove: (selector) =>
          msg = sm.verify_post_remove()
          if (msg is 0)
            #request verified, execute logic
          else if (msg is 1)
            warning_list.push 'removing a post is not socrench, allowed for debug mode'
          else if (msg is 2)
            error_list.push 'post remove requests not entertained'
          
      }
      instances: {
        insert: (selector, options) =>
          msg = sm.verify_instance_insert(args...)
          if (msg is 0)
            #request verified, execute logic
            
          else if (msg is 1)
            warning_list.push 'invalid instance insert request'
          else if (msg is 2)
            error_list.push 'invalid instance insert request'
        update: (selector, mutator, options) =>
          msg = sm.verify_instance_update(args...)
          if (msg is 0)
            #request verified, execute logic
            
          else if (msg is 1)
            warning_list.push 'invalid instance update request'
          else if (msg is 2)
            error_list.push 'invalid instance update request'
        remove: (selector) =>
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