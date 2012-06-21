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
    
    #editing
    "keydown textarea[name='reply_text']": (event) ->  
    #updates composition string while typing. Does not get the character that's entered in after this event triggers.
      if not event.isImmediatePropagationStopped()
        Session.set("composing_#{ @_id }", event.target.value) 
        Meteor.flush()
        event.stopImmediatePropagation()
    "blur textarea[name='reply_text']": (event) ->    
      #updates the composition string on blur. Captures the last character missed by the keydown function.
      if not event.isImmediatePropagationStopped()
        Session.set("composing_#{ @_id }", event.target.value) 
        Meteor.flush()
        event.stopImmediatePropagation()# are these needed?  ...I think so.  
       
    #submit a reply.  
    "click button[name='reply_submit']": (event) ->
      if not event.isImmediatePropagationStopped()
        #getting from Session.get("composing_#{ @_id }") freezes the button.
        replyTextBox = event.target.parentNode.getElementsByTagName("textarea")[0]
        replyContent = replyTextBox.value #no longer required --- > Session.get("composing_#{ @_id }")
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
        event.stopImmediatePropagation()
     
     #cancel a reply
     "click button[name='reply_cancel']": (event) ->
       Session.set("composing_#{ @_id }", undefined)
       Meteor.flush()
       console.log(Session.get("composing_#{ @_id }"))
  }
)