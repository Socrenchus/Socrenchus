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
      if !event.isImmediatePropagationStopped()
        Session.set("composing_#{ @_id }", "")
        event.stopImmediatePropagation()
    
    #editing
    "keypress textarea[name='reply_text']": (event) ->
      if !event.isImmediatePropagationStopped()
        Session.set("composing_#{ @_id }", event.target.value)
        console.log(@reply_box_content)
        Meteor.flush()
        event.stopImmediatePropagation()# are these needed?  ...I think so.  
    
    #submit a reply.  
    "click button[name='reply_submit']": (event) ->
      if !event.isImmediatePropagationStopped()
        # no longer required ---> replyTextBox = event.target.parentNode.getElementsByTagName("textarea")[0]
        event.stopImmediatePropagation()
        replyContent = Session.get("composing_#{ @_id }")#no longer required --- > replyTextBox.value
        console.log("ID of Post you're replying to: #{ @_id }")
        console.log("Reply content: #{replyContent}")
        if(replyContent=="") #can do other checks to prevent them from submitting all whitespace stuff
          alert('Come on bro, write more than that!')#debugging why we're selecting the wrong text box.
        else
          replyID = Posts.insert(
            {
              content: replyContent,
              parent_id: @_id,
              instance_id: @instance_id
            }
          )
          console.log("ID of new post: "+replyID)
          Session.set("composing_#{ @_id }", undefined) #the clean up.
     
     #cancel a reply
     "click button[name='reply_cancel']": (event) ->
       Session.set("composing_#{ @_id }", undefined)
       Meteor.flush()
       console.log(Session.get("composing_#{ @_id }"))    
  }
)