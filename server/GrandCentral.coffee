_debug = true

class GrandCentral
  constructor: (@collection, @method) ->
    @default =
      Meteor.default_server.method_handlers["/#{@collection}/#{@method}"]
    Meteor.default_server.method_handlers["/#{@collection}/#{@method}"] =
      @dispatch
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
          #console.log args[0]
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
    else
      console.error (error_list)
    console.log 'GrandCentral is operational!!'
    error_list = []


Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      gc = new GrandCentral(collection, method)
)
