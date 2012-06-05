testUtils =
  states: 
    none: 0
    typing: 1
  state: 0
  currtag: ''
  defaultTestOptions:
    id: 'tagbox',
    selector: '#tagbox',
    voteboxOptions : {}
  
  init : (options) ->
    testUtils.reset()
    opts = $.extend {}, testUtils.defaultTestOptions, options
    tagbox = $(opts.selector).tagbox(opts.voteboxOptions)
    $(opts.selector).bind('tagSync', testUtils.setTag)
    $(opts.selector).bind('typingTag', testUtils.setState)
    $(opts.selector).bind('unfocusingTagBox', testUtils.setState)
    return $(opts.selector)

  setState: (event, state) ->
    testUtils.state = state

  setTag: (event, tag) ->
    testUtils.currtag = tag

  reset: ->
    $(testUtils.defaultTestOptions.selector).unbind('tagSync', testUtils.setTag)
    $(testUtils.defaultTestOptions.selector).unbind('typingTag', testUtils.setState)
    $(testUtils.defaultTestOptions.selector).unbind('unfocusingTagBox', testUtils.setState)
    $(testUtils.defaultTestOptions.selector).remove()
    $('body').append($("<div id=#{testUtils.defaultTestOptions.id}></div>"))
    testUtils.state = testUtils.states.none
    testUtils.currtag = ''

describe('no interaction', ( ->
    it('should have none state', ( ->
      expect(testUtils.state).toEqual(testUtils.states.none)
      )
    )
    
    it('should have no tags added', ( ->
      expect(testUtils.currtag).toEqual('')
      )
    )
    $('#snapshot').trigger('render', 'nointeraction') 
  )
)

describe('adding tags', ( ->
    it('tag string should equal hello world', ( ->
      tagbox = testUtils.init()
      tagbox.find('.ui-tagtext:eq(0)').click()
      tagbox.find('.ui-individualtag:eq(0)').text('hello world')      
      e = jQuery.Event('keydown')
      e.keyCode = 13
      $('#tagbox .ui-tagtext:eq(0)').trigger(e)
      #expect(testUtils.currtag).toEqual('hello world')
      )
    )

    it('adding multiple tags, last one should be hello multiverse', ( -> 
      tagbox = testUtils.init()
      tagbox.find('.ui-tagtext:eq(0)').click()
      for i in [1..10]
        tagbox.find('.ui-individualtag:eq(0)').text('hello world')      
        e = jQuery.Event('keydown')
        e.keyCode = 13
        $('#tagbox .ui-tagtext:eq(0)').trigger(e)
      tagbox.find('.ui-individualtag:eq(0)').text('hello multiverse')      
      e = jQuery.Event('keydown')
      e.keyCode = 13
      $('#tagbox .ui-tagtext:eq(0)').trigger(e)
      #expect(testUtils.currtag).toEqual('hello multiverse')
      )
    )
    $('#snapshot').trigger('render', 'multipleclickshellomultiverse')
  )
)

describe('checking states', ( ->
    it('state should be typing', ( ->
      tagbox = testUtils.init()
      tagbox.find('.ui-tagtext:eq(0)').click()
      tagbox.find('.ui-individualtag:eq(0)').text('hello world')
      #expect(testUtils.state).toEqual(testUtils.states.typing)
      )
    )
    it('state should be none', ( ->
      e = jQuery.Event('focusout')
      $('#tagbox .ui-tagtext:eq(0)').trigger(e)
      expect(testUtils.state).toEqual(testUtils.states.none)
      )
    )
    
    $.doTimeout(100, -> $('#snapshot').trigger('render', 'statecheck'))
  )
)

