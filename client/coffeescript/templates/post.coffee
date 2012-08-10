_.extend( Template.post,
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
    
  avatar: ->
    hash = hex_md5("#{@_id}@example.com")
    return "http://www.gravatar.com/avatar/#{hash}"
    
  content: ->
    ###
    1. Raw input is assumed in Content.
    2. Raw input converted using Showdown.
    3. Output of step 2 is subjected to Whitelist.
    4. Links are made ready for oembed.
    ###
    #1. @content contains the raw input.
    raw_input = @content
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
  
  reply_count: ->
    Meteor.call('get_reply_count', @_id, (err, res) ->
      return res
    )
  
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
        Session.set('current_post', @_id)
        Session.set('composing', '')
        #give the reply text area focus
        Meteor.defer(-> $("#reply_text").focus())
        event.stopPropagation()
  }
  
)
