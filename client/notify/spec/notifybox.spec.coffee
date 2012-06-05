testUtils =
  state: 0
  messages: []
  messagecount: 0

  states: 
    none: 0,
    open: 1
  defaultTestOptions:
    id: 'notify',
    selector: '#notify',
    notifyOptions : {}
  
  init : (options) ->   
    testUtils.reset()
    opts = $.extend {}, testUtils.defaultTestOptions, options    
    $(opts.selector).notify(opts)
    $(opts.selector).bind('notifyClicked', testUtils.setstate) 
    $(opts.selector).bind('documentClicked', testUtils.setstate)  
    $(opts.selector).bind('messagesadded', testUtils.setmessages)
    return $(opts.selector)

  setstate: (event, state) ->
    testUtils.state = state

  setmessages: (event, params) ->
    testUtils.messages = params['messages']
    testUtils.messagecount = params['messagecount']
    alert 'count ' + testUtils.messagecount

  reset: ->
    $(testUtils.defaultTestOptions.selector).unbind('notifyClicked', testUtils.setstate)
    $(testUtils.defaultTestOptions.selector).unbind('documentClicked', testUtils.setstate)
    $(testUtils.defaultTestOptions.selector).unbind('messagesadded', testUtils.setmessages)
    $(testUtils.defaultTestOptions.selector).remove()
    $('body').append($("<div id=#{testUtils.defaultTestOptions.id}></div>"))
    testUtils.state = testUtils.states.none
    testUtils.messages = []
    testUtils.messagecount = 0

describe('checking states', ( ->
    it('should have none state', ( ->
      notify = testUtils.init()
      expect(testUtils.state).toEqual(testUtils.states.none)
      )
    )    
    $('#snapshot').trigger('render', 'noclick')

    it('should have open state', ( ->
      notify = testUtils.init()
      notify.find('#notification-counter').click()
      expect(testUtils.state).toEqual(testUtils.states.open)
      )
    )
    $.doTimeout(1, -> $('#snapshot').trigger('render', 'click'))
  )
)

describe('checking messages', ( ->
    it('should have 1 message', ( ->
      messages = []
      messages.push('hello world')
      notify = testUtils.init({notificationCount: messages.length, messages: messages})
      expect(testUtils.messagecount).toEqual(1)
      )
    )    
    $('#snapshot').trigger('render', '1message')
  )
)
