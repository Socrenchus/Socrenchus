_.extend( Template.welcome,
  home: -> Session.get('home')
  login_required: -> " disabled='disabled'" unless Session.get('user_id')?
  button_message: ->
    if Session.get('user_id')?
      return "Start a conversation!"
    else
      return "Login to get started. <i class='icon-hand-up'></i>"

    
  am_saying: ->
    return !Session.equals('composing', undefined)
    
  reply_box_content: ->
    Session.get('composing')
    
  events: {
    #start composing
    "click button[name='start_reply']": (event) ->
      if not event.isPropagationStopped()
        discard = true
        if Session.get('composing')? && Session.get('composing') != ''
          discard = confirm('You are currently replying to another post.'+
            '  Do you want to discard that reply?')
        if discard
          Session.set('composing', '')
        event.stopPropagation()
    
    #editing
    """
    keydown textarea[name='reply_text'],
    keyup textarea[name='reply_text']
    """: (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set('composing', event.target.value)
        Meteor.flush()
        event.stopImmediatePropagation()
        
    #submit a reply.
    "click button[name='reply_submit']": (event) ->
      if not event.isImmediatePropagationStopped()
        reply_content = Session.get('composing') #replyTextBox.value
        if(reply_content=='')
          alert('Your reply is empty!')
        else
          reply_id = Posts.insert(
            {
              content: reply_content,
              domain: window.instance
            }
          )
          Router.navigate("p/#{reply_id}", true)
          console.log('ID of new post: '+reply_id)
          Session.set('composing', undefined) #the clean up.
        event.stopImmediatePropagation()
        Meteor.flush()
     
    #cancel a reply
    "click button[name='reply_cancel']": (event) ->
      Session.set('composing', undefined)
      Meteor.flush()
  }
      
)




