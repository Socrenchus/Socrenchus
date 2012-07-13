#when _debug is on: All db actions are executed
#                   Errors printed on console are ignored
#when off, db actions are blocked if any errors are encountered.
_debug = true

class GrandCentral
  constructor: (@collection, @method) ->
    @default =
      Meteor.default_server.method_handlers["/#{@collection}/#{@method}"]
    Meteor.default_server.method_handlers["/#{@collection}/#{@method}"] =
      @dispatch
      
  error_list = []
  dispatch: (args...) =>
    {
      users: {
        insert: =>
          error_list.push('not implemented yet')
        update: =>
          error_list.push('not implemented yet')
        remove: =>
          error_list.push('not implemented yet')
      }
      posts: {
        insert: =>
          args[0] = new ServerPost( args[0] )
        update: =>
          [selector, modifier] = args
          doc = Posts.findOne( selector._id )
          doc = new ClientPost( doc )
          LocalCollection._modify( doc, modifier )
          result = new ServerPost( doc )
          args[1] = result
        remove: (args...) =>
          error_list.push('not implemented yet')
      }
      instances: {
        insert: =>
          error_list.push('not implemented yet')
        update: =>
          error_list.push('not implemented yet')
        remove: =>
          error_list.push('not implemented yet')
      }
    }[@collection][@method]()
    if (error_list.length is 0 or @_debug)
      @default.apply(@, args)
    if (error_list.length>0)
      console.error(error_list)
    #console.info 'GrandCentral is operational!!'
    error_list = []
   


Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      gc = new GrandCentral(collection, method)
)
