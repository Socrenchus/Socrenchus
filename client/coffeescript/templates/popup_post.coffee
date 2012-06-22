_.extend( Template.popup_post,
  show_post: ->
    not Session.equals('showing_post', undefined)
  showing_post: ->
    Session.get('showing_post')
)