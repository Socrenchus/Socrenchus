_.extend( Template.reply_box,
  is_candidate: -> 
    Session.equals("composing_#{ @_id }", undefined)  #untested; does it work?
  reply_box_content: ->
    if @is_candidate
      ""
    else
      Session.get("composing_#{ @_id }")
  events: {
    "keypress textarea[name='reply_text']": (event) ->
      if !event.isImmediatePropagationStopped()
        Session.set("composing_#{ @_id }", event.target.value)
        console.log(@reply_box_content)
        Meteor.flush()
        event.stopImmediatePropagation()# are these needed?  ...I think so.  
    
    "click button[name='start_reply']": (event) ->
      if !event.isImmediatePropagationStopped()
        Session.set("composing_#{ @_id }", "")
        event.stopImmediatePropagation()
    
    "click button[name='reply_submit']": (event) ->
      if !event.isImmediatePropagationStopped()
        replyTextBox = event.target.parentNode.getElementsByTagName("textarea")[0]
        event.stopImmediatePropagation()
        replyContent = replyTextBox.value
        console.log("ID of Post you're replying to: ")
        console.log("Reply content: #{replyContent}")
        if(replyContent=="")
          alert('Selected Reply Box is Null!')#debugging why we're selecting the wrong text box.
        else
          replyID = Posts.insert(
            {
              content: replyContent,
              parent_id: @_id,
              instance_id: @instance_id
            }
          )
          console.log("ID of new post: "+replyID)
          replyTextBox.value = '' #clear the textbox for giggles -- should probably do this only if the post succeeds.
  }
)