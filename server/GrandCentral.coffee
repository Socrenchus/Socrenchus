class GrandCentral
  constructor: (@collection, @method) ->
    Meteor.default_server.method_handlers["/#{@collection}/#{@method}"] = @dispatch
  dispatch: (args...) =>
    {
      users: {
        insert: (args...) => 
          Users.insert(args...)
        update: (args...) => 
          Users.update(args...)
        remove: (args...) =>
          Users.remove(args...)
      }
      posts: {
        insert: (args...) => 
          Posts.insert(args...)
        update: (args...) -> 
          Posts.update(args...)
        remove: (args...) =>
          Posts.remove(args...)
      }
      instances: {
        insert: (args...) => 
          Instances.insert(args...)
        update: (args...) => 
          Instances.update(args...)
        remove: (args...) =>
          Instances.remove(args...)
      }
    }[@collection][@method](args...)
    console.log "GrandCentral is operational!!"


Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      gc = new GrandCentral(collection, method)
)