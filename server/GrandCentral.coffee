_debug = true

class GrandCentral
  constructor: (@collection, @method) ->
    @default = Meteor.default_server.method_handlers["/#{@collection}/#{@method}"]
    Meteor.default_server.method_handlers["/#{@collection}/#{@method}"] = @dispatch
  dispatch: (args...) =>
    {
      users: {
        insert: (args...) => 
        update: (args...) => 
        remove: (args...) =>
      }
      posts: {
        insert: (args...) ->
          args[0].author_id = Meteor.call('user_id')
        update: (args...) => 
        remove: (args...) =>
      }
      instances: {
        insert: (args...) => 
        update: (args...) => 
        remove: (args...) =>
      }
    }[@collection][@method](args...)
    @default.apply(@, args)
    console.log "GrandCentral is operational!!"


Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      gc = new GrandCentral(collection, method)
)
