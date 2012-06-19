GrandCentral =
  default_action: ->
    console.log('GrandCentral works!')
  users: {
    insert: (args...) -> GrandCentral.default_action()
    update: (args...) -> GrandCentral.default_action()
    remove: (args...) -> GrandCentral.default_action()
  }
  posts: {
    insert: (args...) -> GrandCentral.default_action()
    update: (args...) -> GrandCentral.default_action()
    remove: (args...) -> GrandCentral.default_action()
  }
  instances: {
    insert: (args...) -> GrandCentral.default_action()
    update: (args...) -> GrandCentral.default_action()
    remove: (args...) -> GrandCentral.default_action()
  }


Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      orig = Meteor.default_server.method_handlers["/#{collection}/#{method}"]
      Meteor.default_server.method_handlers["/#{collection}/#{method}"] = (args...) ->
        GrandCentral[collection][method](args...)
        orig(args...)
)