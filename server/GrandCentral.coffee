class GrandCentral
  users: {
    insert: @default_action
    update: @default_action
    remove: @default_action
  }
  posts: {
    insert: @default_action
    update: @default_action
    remove: @default_action
  }
  instances: {
    insert: @default_action
    update: @default_action
    remove: @default_action
  }
  default_action: (args) ->
    #throw 'you broke it'

Meteor.startup( ->
  for collection in ['users','posts','instances']
    for method in ['insert','update','remove']
      orig = Meteor.default_server.method_handlers["/#{collection}/#{method}"]
      Meteor.default_server.method_handlers["/#{collection}/#{method}"] = (args) ->
        GrandCentral[collection][method](args)
        orig(args)
)