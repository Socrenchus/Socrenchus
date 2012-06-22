_.extend( Template.tagbox,
  grad_tags: -> tag for tag of @tags
  suggested_tags: ->
    suggestions = {}
    for post in Posts.find( 'parent_id': @parent_id ).fetch() #get siblings
      for name,info of post.tags #Change to only graduated tags
        suggestions[name] ?= 0
        suggestions[name] += info.weight
    sug_list = ({'name':name, 'weight':weight} for name,weight of suggestions) #get as list
    return (sug_list.sort (a,b) -> return a.weight-b.weight).map (a) -> a.name #sort by weight, then return list of names
)

