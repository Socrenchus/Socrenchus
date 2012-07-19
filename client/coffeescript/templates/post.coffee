_.extend( Template.post,
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
  author_short: -> @author_id.slice(0, 5)
    #hack to get a short author name.  remove
    #  when we have access to usernames.  
  
  tag_on: ->  # July 19
    return Session.equals('tagging', true) and 
      Session.equals('current_post', @_id)
  events: { # July 19
    "click button[name='see_tags']": (event) ->
      if not event.isImmediatePropagationStopped()
        #alert(Session.equals('current_post', @_id))
        
        if Session.equals('tagging', true)
          if Session.equals('current_post', @_id)
            Session.set('tagging', false)
            console.log("Turned off tagging for this post.")
          else
            Session.set('current_post', @_id)
            console.log("Switched to post #{@_id}")
        else
          Session.set('tagging', true)
          Session.set('current_post', @_id)
          console.log("Started tagging on post #{@_id}")
        
        event.stopImmediatePropagation()
  }
)
