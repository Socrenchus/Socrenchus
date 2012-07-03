get_post = (target) ->
  post = target.parentNode
  while post.tagName != 'LI'
    post = post.parentNode
  return post

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
        parent = get_post(event.target).parentNode
        while parent.tagName != 'LI' && parent.id != 'page-body'
          parent = parent.parentNode
        window.scrollTo(parent.offsetLeft, parent.offsetTop)
        event.stopImmediatePropagation()
        
    "click button[name='goto-next-post']": (event) ->
      if not event.isImmediatePropagationStopped()
        next_post = $(get_post(event.target)).next()[0]
        window.scrollTo(next_post.offsetLeft, next_post.offsetTop) if next_post?
        event.stopImmediatePropagation()
        
    "click button[name='goto-prev-post']": (event) ->
      if not event.isImmediatePropagationStopped()
        prev_post = $(get_post(event.target)).prev()[0]
        window.scrollTo(prev_post.offsetLeft, prev_post.offsetTop) if prev_post?
        event.stopImmediatePropagation()
  }
)
