#when _debug is on, all db actions are executed ignoring the errors which are printed on console
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
        insert: (args...) =>
          error_list.push('not implimented yet')
        update: (args...) =>
          error_list.push('not implimented yet')
        remove: (args...) =>
          error_list.push('not implimented yet')
      }
      posts: {
        insert: (args...) =>
          args[0].author_id = Meteor.call('get_user_id')
          args[0].votes = {
            'up': {
              users: []
              weight: 0
            }
            'down': {
              users: []
              weight: 0
            }
          }
          args[0].tags = []
          if (args[0].content == '')
            error_list.push 'blank content in post/insert'
        update: (args...) =>
          error_list.push('not implimented yet')
        remove: (args...) =>
      }
      instances: {
        insert: (args...) =>
          error_list.push('not implimented yet')
        update: (args...) =>
          error_list.push('not implimented yet')
        remove: (args...) =>
      }
    }[@collection][@method](args...)
    if (error_list.length is 0)
      @default.apply(@, args)
    if (error_list.length>0)
      console.error (error_list)
    #console.info 'GrandCentral is operational!!'
    error_list = []


Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      gc = new GrandCentral(collection, method)
)
