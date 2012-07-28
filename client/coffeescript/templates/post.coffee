_.extend( Template.post,
  parent: ->
    parent = Posts.findOne(_id: @parent_id)
    return {exists: parent?, post: parent}

  init: ->
    #function runs on initialization of post
    #takes care of dependencies
    if Session.equals('current_post', undefined)
      Session.set('current_post', @_id)  #volunteer
    if Session.equals('tagging', undefined)
      Session.set('tagging', false)
    if Session.equals('suggested_tags', undefined)
      Session.set('suggested_tags', [])
    return ""
    
  avatar: ->
    hash = hex_md5("#{@_id}@example.com")
    return "http://www.gravatar.com/avatar/#{hash}"
    
  content: ->
    escaped = Handlebars._escape(@content)
    showdown_converter = new Showdown.converter()
    post_content_html = showdown_converter.makeHtml(escaped)
    return post_content_html
  identifier: -> @_id
  link_href: ->
    return "/#{ @_id }"
  parent_href: ->
    if @parent_id?
      return "/#{ @parent_id }"
    else
      return false
  author: -> @author_id
  author_short: -> 
    if typeof @author_id is "string" and @author_id.length>5
      @author_id.slice(0, 5)
    else
      @author_id
    #hack to get a short author name.  remove
    #  when we have access to usernames.  
  
  tag_on: ->  # July 19
    return Session.equals('tagging', true) and 
      Session.equals('current_post', @_id)
  
  has_replied: ->
    Posts.findOne( {'parent_id': @_id, 'author_id': Session.get('user_id')} ) isnt undefined
  
  composing_reply: ->
    return Session.equals('current_post', @_id) and
      not Session.equals('composing', undefined)
  
  composing_any_reply: -> not Session.equals('composing', undefined)
  
  events: { # July 19
    "click button[name='see_tags']": (event) ->
      if not event.isImmediatePropagationStopped()
        #TODO: Turn these commented-out console.logs 
        #      into their proper tron actions.  
        if Session.equals('tagging', true)
          if Session.equals('current_post', @_id)
            Session.set('tagging', false)
            #console.log("Turned off tagging for this post.")
          else
            Session.set('current_post', @_id)
            #console.log("Switched to post #{@_id}")
        else
          Session.set('tagging', true)
          Session.set('current_post', @_id)
          #console.log("Started tagging on post #{@_id}")
        
        event.stopImmediatePropagation()
    
    "click button[name='reply']": (event) ->
      if not event.isImmediatePropagationStopped()
        Session.set('current_post', @_id)
        Session.set('composing', '')
        event.stopImmediatePropagation()
        
    
  }
)
