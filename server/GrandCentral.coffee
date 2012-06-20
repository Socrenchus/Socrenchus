###
trun _debug off for deployment
all db communications go through this class
Grand central calls the station master to check args
this file overrides default meteor methods that handle the same with mongo.
###

_debug = true

class GrandCentral
  error_list = []
  warning_list = []
  sm = new StationMaster (@_debug)
  
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
          args[0].author_id = Session.get 'user_id'
          console.log args[0] #print out the object
          
        update: (args...) => 
        remove: (args...) =>
      }
      instances: {
        insert: (args...) =>
        update: (args...) =>
        remove: (args...) =>
      }
    }[@collection][@method](args...)
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