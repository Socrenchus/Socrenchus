testUtils =
  state: 0
  votetextVal: ''
  votecount: 0

  states: 
    none: 0,
    up: 1,
    down: 2
  defaultTestOptions:
    id: 'votebox',
    selector: '#votebox',
    voteboxOptions : {local:true}
  
  init : (options) ->
    testUtils.reset()
    opts = $.extend {}, testUtils.defaultTestOptions, options
    $(opts.selector).votebox(opts.voteboxOptions)    
    $(opts.selector).bind('upArrowPressed', testUtils.upArrowPressed)
    $(opts.selector).bind('downArrowPressed', testUtils.downArrowPressed)
    $(opts.selector).bind('votetextChanged', testUtils.votetextChanged)
    return $(opts.selector)

  votetextChanged: (event, params) ->
    testUtils.votetextVal = params['votetext']
    testUtils.votecount = params['votecount']

  upArrowPressed: (event, state) ->
    testUtils.state = state

  downArrowPressed: (event, state) ->
    testUtils.state = state

  reset: ->
    $(testUtils.defaultTestOptions.selector).unbind('upArrowPressed', testUtils.upArrowPressed)
    $(testUtils.defaultTestOptions.selector).unbind('downArrowPressed', testUtils.downArrowPressed)
    $(testUtils.defaultTestOptions.selector).unbind('votetextChanged', testUtils.votetextChanged)
    $(testUtils.defaultTestOptions.selector).remove()
    $('body').append($("<div id=#{testUtils.defaultTestOptions.id}></div>"))
    testUtils.state = testUtils.states.none
    testUtils.votetextVal = ''
    testUtils.votecount = 0

describe('votebox unclicked', ( ->
    it('should have none state', ( ->
      voteox = testUtils.init()
      expect(testUtils.state).toEqual(testUtils.states.none)
      )
    )

    it('should have no text', ( ->
      expect(testUtils.votetextVal).toEqual('')
      )
    )
    $('#snapshot').trigger('render', 'noclick')
  )
)

describe('votebox up clicked', ( ->
    it('should have up state', ( ->    
      votebox = testUtils.init()
      votebox.find('#ui-upvote').click()
      expect(testUtils.state).toEqual(testUtils.states.up)
      )
    )
      
    it('should have text equivalence to votes', ( ->
      expect(testUtils.votetextVal).toEqual(testUtils.votecount)
      )
    )
    $('#snapshot').trigger('render', 'upvoteclicked')
  )
)

describe('votebox down clicked', ( ->    
    it('should have down state', ( ->
      votebox = testUtils.init()
      votebox.find('#ui-downvote').click()
      expect(testUtils.state).toEqual(testUtils.states.down)
      )
    )
    
    it('should have text equivalence to votes', ( ->
      expect(testUtils.votetextVal).toEqual(testUtils.votecount)
      )
    )
    $('#snapshot').trigger('render', 'downvoteclicked')
  )
)

describe('votebox down clicked 10 times and then up clicked 10 times', ( ->
    it('should have down state', ( ->
      votebox = testUtils.init()
      for i in [1..10]
        votebox.find('#ui-downvote').click()
      for i in [1..10]
        votebox.find('#ui-upvote').click()
      expect(testUtils.state).toEqual(testUtils.states.down)
      )
    )
    
    it('should have text equivalence to votes', ( ->
      expect(testUtils.votetextVal).toEqual(testUtils.votecount)
      )
    )
    $.doTimeout(10, -> $('#snapshot').trigger('render', 'downvote10clicked'))
  )
)
