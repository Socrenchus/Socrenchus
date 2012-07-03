###
#Rules for switching to new schema:
# -info -> weight
# -info.weight -> weight
# -'TODO's indicate case-specific changes
###
_.extend( Template.tagbox,
  visible_tags: ->
    @my_tags ?= []                    #TODO: REMOVE on schema change
    visible = (tag for tag of @tags)  #graduated tags
    for tag in @my_tags              #my tags
      if not (tag in visible)
        visible.push(tag)
    return {suggested:false,tags:visible}
    
  suggested_tags: ->
    suggestions = Session.get("suggestions_#{ @_id }")
    filtered = []
    for tag in suggestions
      filtered.push(tag) if tag? &&
        tag.search(Session.get("filter_text_#{ @_id }")) != -1
    return {suggested:true,tags:filtered}

  tagging_post: -> Session.equals("tagging_#{ @_id }", true)
  
  events: {
    
    'keydown .suggested': (event) ->
      if not event.isImmediatePropagationStopped()
        tag_text = event.target.innerText
        
        #TODO: modify for new HTML layout,
        #      or find less convoluted way to get particular elements
        tag_box = event.target.parentNode.parentNode.
          getElementsByTagName('div')[1].
          getElementsByTagName('textarea')[0]
        
        switch event.keyCode
          when 74 #J/Check
            Template.tagbox.add_tag(@_id, @my_tags, tag_text, tag_box)
          when 75 #K/Kill
            Session.get("suggestions_#{ @_id }").remove(tag_text)
            Session.get("context_#{@_id}").invalidate()
          
        event.stopImmediatePropagation()
    
    "keyup textarea[name='tag_text']": (event) ->
      if not event.isImmediatePropagationStopped()
      
        entered_text = event.target.value
        
        #TODO: modify for new HTML layout,
        #      or find less convoluted way to get particular elements
        suggested_tag = event.target.parentNode.parentNode.
          getElementsByTagName("div")[0].
          getElementsByTagName("form")[0]?.innerText
        
        switch event.keyCode
          when 13 #Enter: ADD ENTERED TEXT
            console.log(@_id)
            Template.tagbox.add_tag(@_id, @my_tags, entered_text, event.target)
          when 37 #Left-arrow: ADD SUGGESTED TAG
            if event.ctrlKey && suggested_tag?
              Template.tagbox.add_tag(@_id, @my_tags,
                suggested_tag, event.target)
          when 39 #Right-arrow: REMOVE SUGGESTED TAG
            if event.ctrlKey
              Session.get("suggestions_#{ @_id }").remove(suggested_tag)
              Session.get("context_#{@_id}").invalidate()
          else    #Update filter with new text
            Session.set("filter_text_#{ @_id }", entered_text)
            Session.get("context_#{@_id}").invalidate()
          
        event.stopImmediatePropagation()
        
    #Suppresses newline
    "keydown textarea[name='tag_text']": (event) ->
      if not event.isImmediatePropagationStopped()
        switch event.keyCode
          when 13 #Enter
            event.preventDefault()
        event.stopImmediatePropagation()
    
    "click button[name='tag_button']": (event) ->
      if not event.isImmediatePropagationStopped()
      
        Session.set("tagging_#{ @_id }", true)  #Display tagbox
        
        Session.set("suggestions_#{ @_id }",
          if @suggestions? then @suggestions else [])
        
        event.stopImmediatePropagation()
        
    "click button[name='enter_tag']": (event) ->
      if not event.isImmediatePropagationStopped()
        #TODO: modify for new HTML layout,
        #      or find less convoluted way to get particular elements
        tag_box = event.target.parentNode.getElementsByTagName(
          "textarea")[0]
        Template.tagbox.add_tag(@_id, @my_tags, tag_box.value, tag_box)
        event.stopImmediatePropagation()
        
    "click button[name='done_tagging']": (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set("tagging_#{ @_id }", false)
        event.stopImmediatePropagation()
  }
  
  add_tag: (id, my_tags, tag_text, text_box) ->
    my_tags ?= []
    if tag_text != "" && not (tag_text in my_tags)
      my_tags.push(tag_text)
      Posts.update(id, {$set: {'my_tags': my_tags}})
      Session.get("suggestions_#{ id }").remove(tag_text)
    #clear textbox and update suggestion filter
    text_box.value = ''
    Session.set("filter_text_#{ id }", '')
    Session.get("context_#{ id }").invalidate()
)

Handlebars.registerHelper('tags', (context, object) ->
  @my_tags ?= []          #TODO: REMOVE
  ret = ""
  for tag in context.tags
    ret += if context.suggested then "<form" else "<div"
    ret += " class='tag"
    ret += " grad" if @tags[tag]?
    ret += " mytag" if tag in @my_tags
    ret += " suggested" if context.suggested
    ret += "'>" + tag
    ret += if context.suggested then "</form>" else "</div>"
  return ret
)

