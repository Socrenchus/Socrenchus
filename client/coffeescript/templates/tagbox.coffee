_.extend( Template.tagbox,
  classes: ->
    classes = ['tag']
    classes.push('grad') if @tags[@cur]?
    if @my_tags?
      classes.push('mytag') if @cur in @my_tags
    formatted_classes = classes.join(' ')
    return formatted_classes

  displayed_tags: ->
    visible = (tag for tag of @tags)
    if @my_tags?
      for tag in @my_tags
        if not (tag in visible)
          visible.push(tag)
    return visible
    
  suggested_tags: ->
    filtered = []
    for tag in Session.get('suggested_tags')
      if tag? && tag.search(Session.get('filter_text')) != -1
        filtered.push(tag)
    return filtered

  tagging_post: ->
    Session.equals('tagging', true) && Session.equals('current_post', @_id)
  
  events: {
    
    #Key interaction with suggested tag items
    'keydown .suggested': (event) ->
      if not event.isImmediatePropagationStopped()
        tag_text = event.target.innerText
        
        switch event.keyCode
          when 74 #J/Check
            Template.tagbox.add_tag(@_id, tag_text)
          when 75 #K/Kill
            #WORKAROUND.  Session is not yet reactive with arrays or objects.
            temp = Session.get('suggested_tags')
            temp.remove(tag_text)
            Session.set('suggested_tags',temp.clone())
          
        event.stopImmediatePropagation()
    
    #Key interaction with text area
    "keyup textarea[name='tag_text']": (event) ->
      if not event.isImmediatePropagationStopped()
        entered_text = event.target.value
        
        #Get first filtered suggestion
        for tag in Session.get('suggested_tags')
          if tag.search(Session.get('filter_text')) != -1
            suggested_tag = tag
            break
        
        switch event.keyCode
          when 13 #Enter: ADD ENTERED TEXT
            Template.tagbox.add_tag(@_id, entered_text)
          when 37 #Left-arrow: ADD SUGGESTED TAG
            if event.ctrlKey && suggested_tag?
              Template.tagbox.add_tag(@_id, suggested_tag)
          when 39 #Right-arrow: REMOVE SUGGESTED TAG
            if event.ctrlKey
              #WORKAROUND.  Session is not yet reactive with arrays or objects.
              temp = Session.get('suggested_tags')
              temp.remove(suggested_tag)
              Session.set('suggested_tags',temp.clone())
          else    #Update filter with new text
            Session.set('filter_text', entered_text)
        
        Meteor.autosubscribe(=>
          if Session.equals('filter_text', '')
            event.target.value = ''
        )
        
        event.stopImmediatePropagation()
    
    #Suppresses newline
    "keydown textarea[name='tag_text']": (event) ->
      if not event.isImmediatePropagationStopped()
        switch event.keyCode
          when 13 #Enter
            event.preventDefault()
        event.stopImmediatePropagation()
    
    "click button[name='start_tagging']": (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set('tagging', true)
        Session.set('current_post', @_id)
        Session.set('suggested_tags', @suggested_tags)
        Session.set('filter_text', '')
        event.stopImmediatePropagation()
        
    "click button[name='enter_tag']": (event) ->
      if not event.isImmediatePropagationStopped()
        Template.tagbox.add_tag(@_id, Session.get('filter_text'))
      return false
        
    "click button[name='done_tagging']": (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set('tagging', false)
      return false
  }
  
  add_tag: (id, tag_text) ->
    Session.set('filter_text', '')
    if tag_text != ''
      q = {'$set': {}}
      q['$set']["my_tags.#{tag_text}"] = 1
      Posts.update({ '_id': id}, q)
      #WORKAROUND.  Session is not yet reactive with arrays or objects.
      temp = Session.get('suggested_tags')
      temp.remove(tag_text)
      Session.set('suggested_tags',temp.clone())
    Meteor.flush()
)