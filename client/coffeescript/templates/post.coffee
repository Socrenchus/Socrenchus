_.extend( Template.post,
  post_span: ->
    #Returns span10 or span7, depending on whether tagbox is visible.
    if Session.equals('tagging', true) and Session.equals('current_post', @_id)
      return 'span7'
    else
      return 'span10'

  parent: ->
    parent = Posts.findOne(_id: @parent_id)
    return {exists: parent?, post: parent}

  #QQQ
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
      
    ###
    1. Raw input is assumed in Content.
    2. Raw input converted using Showdown.
    3. Output of step 2 is subjected to Whitelist.
    4. Links are made ready for oembed.
    ###
    return '' unless @content?
    raw_input = Handlebars._escape(@content);
    #1. @content contains the raw input.
    #raw_input = @content
    #2. Convert raw input using Showdown.
    showdown_converter = new Showdown.converter()
    raw_showdown = showdown_converter.makeHtml(raw_input)
    #3. Output subjected to whitelist.
    # NotImplementedYet
    cooked_showdown = raw_showdown
    #4. Links made ready for Oembed.
    replacement = '$1<div><a href="$2" class="oembed">$2</a></div>'
    oembedded = cooked_showdown.replace('<a', "<a class='oembed'")
    oembedded = oembedded.replace(/(\s|>|^)(https?:[^\s<]*)/igm, replacement)
    oembedded = oembedded.replace(/(\s|>|^)(mailto:[^\s<]*)/igm, replacement)
    Meteor.defer( -> $('a.oembed').oembed().removeClass('oembed') )
    return oembedded
    
    
  identifier: -> @_id
  link_href: -> Router.link("/p/#{ @_id }")
  
  author_name: -> 
    if @author?.name?
      return @author?.name
    else if @author?.username?
      return @author?.username
    else 
      return ''
  
  #a similar function exists in post_wrapper --phil
  email_hash: ->
    this_post = Posts.findOne( _id: @_id )
    author = this_post?.author
    return window.get_primary_email(author).md5()
  
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
    Posts.findOne( {'parent_id': @_id, 'author_id': Meteor.userId()} ) isnt undefined
  composing_reply: ->
    return Session.equals('current_post', @_id) and
      not Session.equals('composing', undefined)
  composing_any_reply: -> not Session.equals('composing', undefined)
  
  reply_count: ->
    ct = @reply_count
    if ct is 1
      return '1 reply'
    else
      return "#{ct} replies"
  
  time: ->
    return (new Date(@time)).relative()
  
  events: { # July 19
    "click button.toggle-tagbox": (event) ->
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
      if not event.isPropagationStopped()
        if Meteor.userId()?
          Session.set('current_post', @_id)
          Session.set('composing', '')
          #give the reply text area focus
          Meteor.defer(-> $("#reply_text").focus())
        
        event.stopPropagation()
  }
  
  login_required: -> !Meteor.userId()?
  
  login_to: -> 'Login to ' unless Meteor.userId()?
  
)
