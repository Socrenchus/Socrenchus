Meteor.methods(
  use_branch: ( branch ) ->
    Session.set( 'branch', branch )
)

if Meteor.is_client
  # Backbone router
  class Router extends Backbone.Router
    routes:
      "branch/:branch*other": "use_branch"

    use_branch: (branch, other) ->
      Meteor.call( 'use_branch', branch )
      if other?
        Backbone.history.navigate(other, trigger: true)
        @navigate("/branch/#{branch}#{other}")
    
  Router = new Router()