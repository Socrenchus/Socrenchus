_.extend( Template.tagbox,
  grad_tags: -> tag for tag of @tags
  suggested_tags: ->
    suggestions = {}
    for post in Posts.find( 'parent_id': @parent_id ).fetch() #get siblings
      for name,info of post.tags #Change to only graduated tags
        suggestions[name] ?= 0
        suggestions[name] += info.weight
    sug_list = ({'name':name, 'weight':weight} for name,weight of suggestions)
    #sort by weight, then return list of names
    cmp_weight = (a,b) -> a.weight - b.weight
    return sug_list.sort( cmp_weight ).map( (a) -> a.name )
)

