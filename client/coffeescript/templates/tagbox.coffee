Array.prototype.clone = ->
  return this.slice(0)

_.extend( Template.tagbox,

  displayed_tags: ->
    @my_tags ?= []                    #TODO: REMOVE on schema change
    visible = (tag for tag of @tags)
    for tag in @my_tags
      if not (tag in visible)
        visible.push(tag)
    return { suggested: false, tags: visible }
    
  suggested_tags: ->
    filtered = []
    for tag in Session.get('suggested_tags')
      if tag? && tag.search(Session.get('filter_text')) != -1
        filtered.push(tag)
    return { suggested: true, tags: filtered }

  tagging_post: ->
    Session.equals('tagging', true) && Session.equals('current_post', @_id)
  
  events: {
    
    #Key interaction with suggested tag items
    'keydown .suggested': (event) ->
      if not event.isImmediatePropagationStopped()
        tag_text = event.target.innerText
        
        switch event.keyCode
          when 74 #J/Check
            Template.tagbox.add_tag(@_id, @my_tags, tag_text)
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
        
        for tag in Session.get('suggested_tags')
          if tag.search(Session.get('filter_text')) != -1
            suggested_tag = tag
            break
        
        switch event.keyCode
          when 13 #Enter: ADD ENTERED TEXT
            Template.tagbox.add_tag(@_id, @my_tags, entered_text)
          when 37 #Left-arrow: ADD SUGGESTED TAG
            if event.ctrlKey && suggested_tag?
              Template.tagbox.add_tag(@_id, @my_tags, suggested_tag)
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
        @suggestions ?= []    #TODO: REMOVE after schema change
        Session.set('suggested_tags', @suggestions)
        Session.set('filter_text', '')
        event.stopImmediatePropagation()
        
    "click button[name='enter_tag']": (event) ->
      if not event.isImmediatePropagationStopped()
        Template.tagbox.add_tag(@_id, @my_tags,
          Session.get('filter_text'))
      return false
        
    "click button[name='done_tagging']": (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set('tagging', false)
      return false
  }
  
  add_tag: (id, my_tags, tag_text) ->
    Session.set('filter_text', '')
    if tag_text != '' && not (tag_text in my_tags)
      q = {'$set': {}}
      q['$set']["my_tags.#{tag_text}"] = 1
      #tron.log(q)
      Posts.update({ '_id': id}, q)
      @suggestions?.remove(tag_text)
    Meteor.flush()
)

# TODO: Remove this helper ASAP, handle bar helper abuse is bad and ugly.
#   The point of templates is so that we don't generate HTML in our script
#   files, if I wanted to do this I would have kept the old app engine
#   system.
Handlebars.registerHelper('tags', (context, object) ->
  @my_tags ?= []          #TODO: REMOVE
  ret = ''
  for tag in context.tags
    ret += if context.suggested then "<div tabindex='0'" else '<div'
    ret += " class='tag"
    ret += ' grad' if @tags[tag]?
    ret += ' mytag' if tag in @my_tags
    ret += ' suggested' if context.suggested
    ret += "'>" + tag + '</div>'
  return ret
)

