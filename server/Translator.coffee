class Translator
  add_change: (doc, idx, publisher) ->
    #every time a post is added, translate to client schema and publish
    user_id = Meteor.call('get_user_id')
    client_tags = {}
    client_my_tags = {}
    client_votes = {
      'up' : {
        count: 0
        weight: 0
      }
      'down' : {
        count: 0
        weight: 0
      }
    }
    client_my_vote = undefined
    for tag of doc.tags
      client_tags[tag] = doc.tags[tag].weight
      #console.log doc.tags[tag].users
      #doc.tags[tag].users?.push(user_id) #used to test the following loop
      if (doc.tags[tag].users? and (user_id in doc.tags[tag].users))
        #console.log 'personal tag'
        client_my_tags[tag] = doc.tags[tag].weight
      for vote of doc.votes
        #console.log doc.votes[vote]
        client_votes[vote].count = doc.votes[vote].users.length
        client_votes[vote].weight = doc.votes[vote].weight
        if (user_id in doc.votes[vote].users)
          if (vote is 'up')
            client_my_vote = true
          if (vote is 'down')
            client_my_vote = false
        
    #suggested tags
    client_suggested_tags = []
    suggestions = {}
    for post in Posts.find( 'parent_id': doc._id ).fetch()
      for tag_key of post.tags
        if (tag_key not in client_my_tags)
          suggestions[tag_key] ?= 0
          suggestions[tag_key] += doc.tags[tag_key].weight
    sug_list = ({'name':n, 'weight':w} for n,w of suggestions)
    #sort by weight, then return list of names
    cmp_weight = (a,b) -> a.weight - b.weight
    client_suggested_tags = sug_list.sort( cmp_weight ).map( (a) -> a.name )
    #tron.log 'suggested tags:'
    #tron.log client_suggested_tags
    #end suggested tags
        
    publisher.set("posts", doc._id, {
      author_id : doc.author_id
      content : doc.content
      parent_id : doc.parent_id
      tags: client_tags
      my_tags: client_my_tags
      votes: client_votes
      my_vote: client_my_vote
      suggested_tags: client_suggested_tags
    })
    publisher.flush()

translator = new Translator