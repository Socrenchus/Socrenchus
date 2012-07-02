Meteor.methods(
  use_branch: ( branch ) ->
    Session.set( 'branch', branch )
)

if Meteor.is_client
  # Backbone router
  class Router extends Backbone.Router
    routes:
      "branch/:branch": "use_branch"

    use_branch: (branch) ->
      Meteor.call( 'use_branch', branch )
    
  Router = new Router()