class @SharedPost
  constructor: ( either ) ->
    # define the shared client-server schema
    _.extend( @,
      _id: ''
      parent_id: undefined
      content: ''
      domain: 'socrench.us'
      time: new Date()
    )
    
    for key in [ '_id', 'parent_id', 'content', 'domain', 'time' ]
      @[key] = either[key] if either[key]?
  
  is_graduated: ( tag, server_post ) =>
    # TODO: Improve this function
    grad = false
    if server_post.tags[tag]?
      grad = server_post.tags[tag].users.length > 1
    else grad = false
    return grad
       
