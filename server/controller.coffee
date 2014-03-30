#when _debug is on: All db actions are executed
#                   Errors printed on console are ignored
#when off, db actions are blocked if any errors are encountered.
_debug = true

class Controller
  constructor: (@collection, @method) ->
    @default =
      Meteor.default_server.method_handlers["/#{@collection}/#{@method}"]
    Meteor.default_server.method_handlers["/#{@collection}/#{@method}"] =
      @dispatch
      
  error_list = []
  dispatch: (args...) =>
    deny =
      insert: =>
        error_list.push('not implemented yet')
      update: =>
        error_list.push('not implemented yet')
      remove: =>
        error_list.push('not implemented yet')
    {
      users: deny
      posts: {
        insert: =>
          args[0] = new ServerPost( args[0], Meteor.userId() )
        update: =>
          [selector, modifier] = args
          doc = Posts.findOne( selector._id )
          doc = new ClientPost( doc, Meteor.userId() )
          LocalCollection._modify( doc, modifier )
          result = new ServerPost( doc, Meteor.userId() )
          args[1] = result
        remove: (args...) =>
          error_list.push('not implemented yet')
      }
      instances: deny
      notifications: deny
    }[@collection][@method]()
    if (error_list.length is 0 or @_debug)
      @default.apply(@, args)
    if (error_list.length>0)
      console.error(error_list)
    console.info 'Controller is operational!!'
    error_list = []

Meteor.startup( ->
  for collection in ['users','posts','instances','notifications']
    for method in ['insert','update','remove']
      gc = new Controller(collection, method)
)
