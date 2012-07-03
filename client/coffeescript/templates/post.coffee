_.extend( Template.post,
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

  events: {
    "click button[name='goto-parent']": (event) ->
      if not event.isImmediatePropagationStopped()
        parent = event.target
        #Climb the DOM tree once to get the current post
        #then again for the parent post
        for val in [1,2]
          parent = parent.parentNode
          #Until we hit a post or the top of the stream, keep looking
          while parent.className != 'post_container' && parent.id != 'page-body'
            parent = parent.parentNode
        window.scrollTo(parent.offsetLeft, parent.offsetTop)
        event.stopImmediatePropagation()
  }
)
