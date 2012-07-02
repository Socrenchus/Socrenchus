###
#Rules for switching to new schema:
# -@tags -> @graduated_tags
# -info -> weight
# -info.weight -> weight
# -'TODO's indicate case-specific changes
###
_.extend( Template.tagbox,
  visible_tags: ->
    visible = (tag for tag of @tags)  #graduated tags
    @my_tags ?= {}                    #TODO: REMOVE on schema change
    for name of @my_tags              #my tags
      if not (name in visible)
        visible.push(name)
    return visible
    
  suggested_tags: -> 
    suggestions = Session.get("suggestions_#{ @_id }")
    filtered = []
    for tag in suggestions
      filtered.push(tag) if tag? &&
        tag.search(Session.get("filter_text_#{ @_id }")) != -1
    return filtered

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
            Template.tagbox.add_tag(@_id, @tags, [], tag_text, tag_box)
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
            Template.tagbox.add_tag(@_id, @tags, [], entered_text, event.target)
          when 37 #Left-arrow: ADD SUGGESTED TAG
            if event.ctrlKey && suggested_tag?
              @tags[suggested_tag] ?= { users: [], weight: 0}
              @tags[suggested_tag].users.push(Session.get('user_id'))
              Posts.update(@_id, {$set: {tags: @tags}})
              Session.get("suggestions_#{ @_id }").remove(suggested_tag)
              Session.get("context_#{@_id}").invalidate()
          when 39 #Right-arrow: REMOVE SUGGESTED TAG
            if event.ctrlKey
              Session.get("suggestions_#{ @_id }").remove(suggested_tag)
              Session.get("context_#{@_id}").invalidate()
          else    #Update suggestions with new text
            Session.set("filter_text_#{ @_id }", entered_text)
            Session.get("context_#{@_id}").invalidate()
          
        event.stopImmediatePropagation()
        
    "keydown textarea[name='tag_text']": (event) -> #Suppresses newline
      if not event.isImmediatePropagationStopped()
        switch event.keyCode
          when 13 #Enter
            event.preventDefault()
          
        event.stopImmediatePropagation()
    
    "click button[name='tagbutton']": (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set("tagging_#{ @_id }", true)  #Display tagbox
        
        #MAKE SUGGESTIONS
        @my_tags = {} #TODO: REMOVE on schema change
        suggestions = {}
        #get graduated tags from siblings
        for post in Posts.find( 'parent_id': @parent_id ).fetch()
          for name,info of post.tags
            if post.tags[name]? && (not @my_tags[name]?)
              suggestions[name] ?= 0
              suggestions[name] += info.weight
        sug_list = ({'name':n, 'weight':w} for n,w of suggestions)
        #sort by weight, then return list of names
        cmp_weight = (a,b) -> a.weight - b.weight
        res = sug_list.sort( cmp_weight ).map( (a) -> a.name )
        Session.set("suggestions_#{ @_id }", res)
        
        event.stopImmediatePropagation()
        
    "click button[name='enter_tag']": (event) ->
      if not event.isImmediatePropagationStopped()
        #TODO: modify for new HTML layout,
        #      or find less convoluted way to get particular elements
        tag_box = event.target.parentNode.getElementsByTagName(
          "textarea")[0]
        Template.tagbox.add_tag(@_id, @tags, [], tag_box.value, tag_box)
        event.stopImmediatePropagation()
        
    "click button[name='done_tagging']": (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set("tagging_#{ @_id }", false)
        event.stopImmediatePropagation()
  }
  
  add_tag: (id, grad_tags, my_tags, tag_text, text_box) ->
    if tag_text != "" && not my_tags[tag_text]?
      #TODO: add to my_tags not grad_tags
      grad_tags[tag_text] ?= { users: [], weight: 0}
      grad_tags[tag_text].users.push(Session.get('user_id'))
      Posts.update(id, {$set: {tags: grad_tags}})
      #clear textbox and update suggestion filter
      text_box.value = ''
      Session.set("filter_text_#{ id }", '')
      Session.get("suggestions_#{ id }").remove(tag_text)
      Session.get("context_#{ id }").invalidate()
)

Handlebars.registerHelper('vis_tags', (context, object) ->
  @my_tags = {}          #TODO: REMOVE
  ret = ""
  for tag in context
    ret += "<div class='tag"
    if @tags[tag]?
      ret += " grad"
    if @my_tags?.tag?
      ret += " mytag"
    ret += "'>" + tag + "</div>"
  return ret
)

Handlebars.registerHelper('sug_tags', (context, object) ->
  Session.set("context_#{@_id}",Meteor.deps.Context.current)
  ret = ""
  for tag in context
    ret += "<form class='tag"
    if @tags[tag]?
      ret += " grad"
    ret += " suggested' tabindex='0'>" + tag + "</form>"
  return ret
)
