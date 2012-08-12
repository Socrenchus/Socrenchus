_.extend( Template.welcome,
  showing_post: -> Session.get('showing_post')?
  home: -> Session.get('home')
)