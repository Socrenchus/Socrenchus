_.extend( Template.tagbox,
  classes: ->
    classes = ['tag label']
    if @my_tags? and @my_tags[@cur]?
      classes.push('mytag')
      if @tags[@cur]?
        classes.push('grad label-success') #green - yours+graduated
      else
        classes.push('label-warning') #yellow - yours
    else if @tags[@cur]?
      classes.push('grad label-inverse') #black - graduated
    else
      classes.push('suggested label-info') #blue - suggested
    formatted_classes = classes.join(' ')
    return formatted_classes
  
  titles: ->
    if @my_tags? and @my_tags[@cur]?
      if @tags[@cur]?
        return 'This graduated tag is one of yours.' #green - yours+graduated
      else
        return 'This is one of your tags for this post.' #yellow - yours
    else if @tags[@cur]?
      return 'This tag has graduated for this post.' #black - graduated
    else
      return "This is a suggested tag for this post." #blue - suggested
    
  filter_text: -> 
    filter = Session.get('filter_text')
    filter ?= ''
    return filter
  
  disabled_status: -> _.isEmpty(Session.get('filter_text'))
  
  displayed_tags: ->
    tags = (tag for tag of @tags)
    if @my_tags?
      for tag of @my_tags
        if not (tag in tags)
          tags.push(tag)
    return tags
    
  suggested_tags: ->
    filtered = []
    filter = Session.get('filter_text')
    filter ?= ''
    if filter is ''
      filtered = @suggested_tags
    else 
      filtered = (tag for tag in @suggested_tags when (tag.indexOf(filter) isnt -1))    
    return filtered

  tagging_post: ->
    Session.equals('tagging', true) and Session.equals('current_post', @_id)
  
  add_tag: (id, tag_text) ->
    Session.set('filter_text', '')
    if tag_text != ''
      q = {'$set': {}}
      q['$set']["my_tags.#{tag_text}"] = 1
      Posts.update({ '_id': id}, q)
      #XXX Session is not yet reactive with arrays or objects.
      temp = Session.get('suggested_tags')
      temp.remove(tag_text)
      Session.set('suggested_tags',temp.clone())
    Meteor.flush()
  
  bindParentContext: (context) ->
    @cur = context
    return undefined

  events: {
    
    #Key interaction with suggested tag items
    'keydown .suggested': (event) ->
      if not event.isImmediatePropagationStopped()
        tag_text = event.target.innerText
        
        switch event.keyCode
          when 74 #J/Check
            Template.tagbox.add_tag(@_id, tag_text)
          when 75 #K/Kill
            #XXX Session is not yet reactive with arrays or objects.
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
          if tag.indexOf(Session.get('filter_text')) != -1
            suggested_tag = tag
            break
        
        switch event.keyCode
          when 13 #Enter: ADD ENTERED TEXT
            Template.tagbox.add_tag(@_id, entered_text)
          when 37 #Left-arrow: ADD SUGGESTED TAG
            if event.ctrlKey and suggested_tag?
              Template.tagbox.add_tag(@_id, suggested_tag)
          when 39 #Right-arrow: REMOVE SUGGESTED TAG
            if event.ctrlKey
              #XXX Session is not yet reactive with arrays or objects.
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
        if @suggested_tags?
          Session.set('suggested_tags', @suggested_tags)
        else
          Session.set('suggested_tags', [])
        Session.set('filter_text', '')
        event.stopImmediatePropagation()
        
    "click button[name='enter_tag']": (event) ->
      if not event.isImmediatePropagationStopped()
        Template.tagbox.add_tag(@_id, Session.get('filter_text'))
      return false
  }
)
