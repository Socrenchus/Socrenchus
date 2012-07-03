_.extend( Template.reply_box,
  is_candidate: ->
    Session.equals("composing_#{ @_id }", undefined)
  reply_box_content: ->
    if @is_candidate
      ""
    else
      Session.get("composing_#{ @_id }")
   
  events: {
    #start composing
    "click button[name='start_reply']": (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set("composing_#{ @_id }", "")
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
        Session.set("composing_#{ @_id }", event.target.value)
        Meteor.flush()
        event.stopImmediatePropagation()
        
    #submit a reply.
    "click button[name='reply_submit']": (event) ->
      if not event.isImmediatePropagationStopped()
        reply_content = Session.get("composing_#{ @_id }") #replyTextBox.value
        #console.log("ID of Post you're replying to: #{ @_id }")
        #console.log("Reply content: #{replyContent}")
        if(reply_content=="")
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
          console.log("ID of new post: "+reply_id)
          Session.set("composing_#{ @_id }", undefined) #the clean up.
        event.stopImmediatePropagation()
     
    #cancel a reply
    "click button[name='reply_cancel']": (event) ->
      Session.set("composing_#{ @_id }", undefined)
      Meteor.flush()
  }
)

