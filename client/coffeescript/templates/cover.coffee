_.extend( Template.cover,
  rendered: ->
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
  
  posts: -> Posts.find({}, {sort:{'reply_count':-1}})
    
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
    #submit a reply.
    "click button[name='reply_submit']": (event) ->
      if not event.isImmediatePropagationStopped()
        tmpl = $(event.target).parent().parent().parent().parent()
        reply_content = tmpl.find('#reply_text').val()
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
      
    #XXX - route to first post -- Socrenchus only!
    "click a.announcement-post": (event) ->
      Router.navigate("p/52f54ffc-7e7f-4a8a-8d2e-0fc0bcc92860", true)
    
  }
      
)




