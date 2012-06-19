# trun _debug off for deployment
_debug = true

class GrandCentral
  error_list = []
  warning_list = []
  
  constructor: (@collection, @method) ->
    @default = Meteor.default_server.method_handlers["/#{@collection}/#{@method}"]
    Meteor.default_server.method_handlers["/#{@collection}/#{@method}"] = @dispatch
  dispatch: (args...) =>
    {
      users: {
        insert: (args...) =>
          if not _debug
            warning_list.push 'cant insert a user - not debug mode'
        update: (args...) =>
          if not _debug
            warning_list.push 'cant update a user - not debug mode'
        remove: (args...) =>
          if not _debug
            warning_list.push 'cant update a user - not debug mode'
      }
      posts: {
        insert: (args...) =>
          args[0].author_id = Session.get 'user_id'
        update: (args...) => 
        remove: (args...) =>
      }
      instances: {
        insert: (args...) =>
        update: (args...) =>
        remove: (args...) =>
      }
    }[@collection][@method](args...)
    if error_list.length is 0 && warning_list.length is 0 && not _debug
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