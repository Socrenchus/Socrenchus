_.extend( Template.body,
  events: {
    'click': (event) ->
      if !(event.isPropagationStopped()) && Session.equals("state", 'open')
        Session.set("state", 'closed')
  }
)