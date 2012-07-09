_.extend( Template.reply_box,
  is_candidate: ->
    Session.equals('composing', undefined) ||
    !Session.equals('current_post', @_id)
  reply_box_content: ->
    if @is_candidate
      ''
    else
      Session.get('composing')
  
  events: {
    #start composing
    "click button[name='start_reply']": (event) ->
      if not event.isImmediatePropagationStopped()
        discard = true
        if Session.get('composing')? && Session.get('composing') != ''
          discard = confirm('You are currently replying to another post.'+
            '  Do you want to discard that reply?')
        if discard
          Session.set('current_post', @_id)
          Session.set('composing', '')
        event.stopImmediatePropagation()
      
    ###
    "load textarea[name='reply_text']": (event) ->
      if not event.isImmediatePropagationStopped()
        event.target.focus()
        event.stopImmediatePropagation()
    ###
    
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
        #console.log("ID of Post you're replying to: #{ @_id }")
        #console.log("Reply content: #{replyContent}")
        if(reply_content=='')
          alert('Your reply is empty!')
        else
          reply_id = Posts.insert(
            {
              content: reply_content,
              parent_id: @_id,
              instance_id: @instance_id
              tags: {}
              votes:{
                'up': {
                  users: []
                  weight: 0
                }
                'down': {
                  users: []
                  weight: 0
                }
              }
            }
          )
          console.log('ID of new post: '+reply_id)
          Session.set('composing', undefined) #the clean up.
        event.stopImmediatePropagation()
     
    #cancel a reply
    "click button[name='reply_cancel']": (event) ->
      Session.set('composing', undefined)
      Meteor.flush()
  }
)

