###
#Rules for switching to new schema:
# -@tags -> @graduated_tags
# -info -> weight
# -info.weight -> weight
###

_.extend( Template.tagbox,

  visible_tags: ->
    visible = (tag for tag of @tags)  #graduated tags
    @my_tags ?= {}                    #REMOVE on schema change
    for name of @my_tags              #my tags
      if not (name in visible)
        visible.push(name)
    return visible
    
  suggested_tags: -> Session.get("suggestions_#{ @_id }")
    
  tagging_post: -> Session.equals("tagging_#{ @_id }", true)
  
  events: {
    'load': ->
    'focus .suggested': (event) ->
      if not event.isImmediatePropagationStopped()
        #console.log(event.target,"clicked")
        #event.target.focus()

        event.stopImmediatePropagation()
        
    'keydown .suggested': (event) ->
      if not event.isImmediatePropagationStopped()
        tag_text = event.target.innerText
        
        #remove tag from suggestions list if added or ignored
        remove_suggestion = =>
          sugs = Session.get("suggestions_#{ @_id }")
          sugs.remove(tag_text)
          Session.get("context_#{@_id}").invalidate()
          nextofkin = event.target.parentNode.getElementsByTagName("form")[1]
          #console.log(document.activeElement)
          nextofkin?.focus()
          console.log(document.activeElement)
          
        switch event.keyCode
          when 74 #J/Check
            @tags[tag_text] ?= { users: [], weight: 0}
            @tags[tag_text].users.push(Meteor.call("get_user_id"))
            Posts.update(@_id, {$set: {tags: @tags}})
            remove_suggestion()
          when 75 #J/Check or K/Kill
            remove_suggestion()
            
          
        event.stopImmediatePropagation()
    
    "keydown textarea[name='tag_text']": (event) -> #Suppresses newline
      if not event.isImmediatePropagationStopped()
        switch event.keyCode
          when 13 #Enter
            event.preventDefault()
          when 37 #Left-arrow: ADD
            @tags[tag_text] ?= { users: [], weight: 0}
            @tags[tag_text].users.push(Meteor.call("get_user_id"))
            Posts.update(@_id, {$set: {tags: @tags}})
            Session.get("suggestions_#{ @_id }").shift() #REMOVE
            Session.get("context_#{@_id}").invalidate()  #REMOVE
          when 39 #Right-arrow: REMOVE
            Session.get("suggestions_#{ @_id }").shift()
            Session.get("context_#{@_id}").invalidate()
        event.stopImmediatePropagation()
    
    "keyup textarea[name='tag_text']": (event) ->
      if not event.isImmediatePropagationStopped()
        tag_text = event.target.value
        switch event.keyCode
          when 13 #Enter
            event.target.value = "" #clear textbox
            @tags[tag_text] ?= { users: [], weight: 0}
            @tags[tag_text].users.push(Meteor.call("get_user_id"))
            Posts.update(@_id, {$set: {tags: @tags}})
          else                  #Update suggestions with new text
            sugs = Session.get("suggestions_#{ @_id }")
            results = []
            for tag in sugs
              results.push(tag) if tag? && tag.search(tag_text) != -1
            Session.set("suggestions_#{ @_id }", results)
            Session.get("context_#{@_id}").invalidate()
          
        event.stopImmediatePropagation()
    
    "click button[name='tagbutton']": (event) ->
      if not event.isImmediatePropagationStopped()
        #Display tagbox
        Session.set("tagging_#{ @_id }", true)
        
        #MAKE SUGGESTIONS
        @my_tags = {}              #REMOVE on schema change
        suggestions = {}
        #get graduated tags from siblings
        for post in Posts.find( 'parent_id': @parent_id ).fetch()
          for name,info of post.tags
            if post.tags[name]? && (not @my_tags[name]?)
              suggestions[name] ?= 0
              suggestions[name] += info.weight
        sug_list = {'name':n, 'weight':w} for n,w of suggestions
        #sort by weight, then return list of names
        cmp_weight = (a,b) -> a.weight - b.weight
        res = sug_list.sort( cmp_weight ).map( (a) -> a.name )
        #console.log(res)
        Session.set("suggestions_#{ @_id }", res)
        
        event.stopImmediatePropagation()
        
    "click button[name='enter_tag']": (event) ->
      if not event.isImmediatePropagationStopped()
        tag_text = event.target.parentNode.getElementsByTagName(
          "textarea")[0].value
        if tag_text != "" # && not @my_tags[tag_text]?
          #add to @my_tags not @tags
          @tags[tag_text] ?= { users: [], weight: 0}
          @tags[tag_text].users.push(Meteor.call("get_user_id"))
          Posts.update(@_id, {$set: {tags: @tags}})
        event.stopImmediatePropagation()
        
    "click button[name='done_tagging']": (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set("tagging_#{ @_id }", false)
        event.stopImmediatePropagation()
  }
)

Handlebars.registerHelper('vis_tags', (context, object) ->
  @my_tags = {test: 0}          #REMOVE
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

$(document).keydown( (event) ->
  console.log(document.activeElement)
  event.stopPropagation()
)
