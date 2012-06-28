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
    'focus .suggested': (event) ->
      if not event.isImmediatePropagationStopped()
        #console.log(event.target,"clicked")
        event.target.focus()

        event.stopImmediatePropagation()
        
    'keydown .suggested': (event) ->
      if not event.isImmediatePropagationStopped()
        tag_text = event.target.innerText
        if event.keyCode == 74 #J/Check
          @tags[tag_text] ?= { users: [], weight: 0}
          @tags[tag_text].users.push(Meteor.call("get_user_id"))
          Posts.update(@_id, {$set: {tags: @tags}})
        if event.keyCode == 74 || event.keyCode == 75 #J/Check or K/Kill
          #remove tag from suggestions list if added or ignored
          res = Session.get("suggestions_#{ @_id }")
          res.remove(tag_text)
          Session.set("suggestions_#{ @_id }",res)
          Session.get("context_#{@_id}").invalidate()
          event.target.parentNode.getElementsByTagName("div")[0]?.focus()
          
        event.stopImmediatePropagation()
        
    "keydown textarea[name='tag_text']": (event) ->
      if not event.isImmediatePropagationStopped()
        if event.keyCode == 13 #Enter
          event.preventDefault()
          tag_text = event.target.value
          @tags[tag_text] ?= { users: [], weight: 0}
          @tags[tag_text].users.push(Meteor.call("get_user_id"))
          Posts.update(@_id, {$set: {tags: @tags}})
          event.target.value = "" #clear textbox
        #else                  #Update suggestions
          
          
        event.stopImmediatePropagation()
    
    "click button[name='tagbutton']": (event) ->
      if not event.isImmediatePropagationStopped()
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
        sug_list = ({'name':name, 'weight':weight} for name,weight of suggestions)
        #sort by weight, then return list of names
        cmp_weight = (a,b) -> a.weight - b.weight
        res = sug_list.sort( cmp_weight ).map( (a) -> a.name )
        Session.set("suggestions_#{ @_id }", res)
        
        event.stopImmediatePropagation()
        
    "click button[name='enter_tag']": (event) ->
      if not event.isImmediatePropagationStopped()
        tag_text = event.target.parentNode.getElementsByTagName("textarea")[0].value
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
    ret += "<div class='tag"
    if @tags[tag]?
      ret += " grad"
    ret += " suggested' tabindex='0'>" + tag + "</div>"
  return ret
)
