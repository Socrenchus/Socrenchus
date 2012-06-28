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
  suggested_tags: ->
    @my_tags ?= {}                    #REMOVE on schema change
    suggestions = {}
    #get graduated tags from siblings
    for post in Posts.find( 'parent_id': @parent_id ).fetch()
      for name,info of post.tags
        if not (name in @my_tags)
          suggestions[name] ?= 0
          suggestions[name] += info.weight
    sug_list = ({'name':name, 'weight':weight} for name,weight of suggestions)
    #sort by weight, then return list of names
    cmp_weight = (a,b) -> a.weight - b.weight
    return sug_list.sort( cmp_weight ).map( (a) -> a.name )
  tagging_post: ->
    @tagging ?= false
    @context = Meteor.deps.Context.current
    return @context.run(=>
      @context = Meteor.deps.Context.current
      return @tagging
    )
  events: {
    "click button[name='tagbutton']": (event) ->
      if not event.isImmediatePropagationStopped()
        @tagging = true
        @context.invalidate()
        Meteor.flush()
        event.stopImmediatePropagation()
    "click button[name='enter_tag']": (event) ->
      if not event.isImmediatePropagationStopped()
        @tagging = true
        tag_text = event.target.parentNode.getElementsByTagName("textarea")[0].value
        if tag_text != ""
          @tags[tag_text] ?= { users: [], weight: 0}
          @tags[tag_text].users.push(Meteor.call("get_user_id"))
          console.log(@context)
          Posts.update(@_id, {$set: {tags: @tags}})
          console.log(@context)
        event.stopImmediatePropagation()
  }
)

