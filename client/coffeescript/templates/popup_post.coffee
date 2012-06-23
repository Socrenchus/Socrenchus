_.extend( Template.popup_post,
  show_post: ->
    not Session.equals('showing_post', undefined)
  showing_post: ->
    Session.get('showing_post')
  
  ###
  #   This event map provides a way to
  #     close the popup_post without linking
  #     the user away from the post.
  #   Don't use it.
  #   This means they can't use the back button
  #     to get the post back.
  #   Instead, use the functionality we now have,
  #     which is to make the dimmer link to
  #     the parent folder.
  #   This generates a page refresh, but it's
  #     worth it to make the URL reflect what's
  #     really intended.
  #   That said, if there's a way to change the
  #     URL to ../ without loading the page again,
  #     without making the browser suspect a
  #     phishing attempt,
  #     by all means, use that instead.
  #               --Phil
  events: {
    #close popup_post
    "click #dimmer": (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set('showing_post', undefined)
        event.stopImmediatePropagation()
  }
  ###
)