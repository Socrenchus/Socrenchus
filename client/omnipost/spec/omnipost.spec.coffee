testUtils = 
  state: 0
  panelCount: 0

  states: 
    none: 0,
    open: 1
  defaultTestOptions:
    id: 'omnipost'
    selector: '#omnipost',
    voteboxOptions : {}
  
  init : (options) ->
    testUtils.reset()
    opts = $.extend {}, testUtils.defaultTestOptions, options
    $(opts.selector).omnipost(opts.voteboxOptions)
    $(opts.selector).bind('panelsChanged', testUtils.setPanelCount)
    $(opts.selector).bind('omnicontainerOpened', testUtils.setState)
    $(opts.selector).bind('linkpanelOpened', testUtils.setState)
    $(opts.selector).bind('videopanelOpened', testUtils.setState) 
    $(opts.selector).bind('omnicontainerClosed', testUtils.setState)     
    $(opts.selector)

  setState: (event, state) ->
    testUtils.state = state 

  setPanelCount: (event, count) ->
    testUtils.panelCount = count

  reset: ->
    $(testUtils.defaultTestOptions.selector).unbind('omnicontainerOpened', testUtils.setState)
    $(testUtils.defaultTestOptions.selector).unbind('linkpanelOpened', testUtils.setState)
    $(testUtils.defaultTestOptions.selector).unbind('videopanelOpened', testUtils.setState) 
    $(testUtils.defaultTestOptions.selector).unbind('omnicontainerClosed', testUtils.setState)
    $(testUtils.defaultTestOptions.selector).remove()
    $('body').append($("<div id=#{testUtils.defaultTestOptions.id}></div>"))
    testUtils.state = testUtils.states.none
    testUtils.currtag = ''

describe('state check', ( ->
    it('should have none state', ( ->
      omnipost = testUtils.init()
      expect(testUtils.state).toEqual(testUtils.states.none)
      )
    ) 
    $('#snapshot').trigger('render', 'nointeraction') 
    
    it('should have open state', ( ->
      $('#ui-omniContainer').click()
      expect(testUtils.state).toEqual(testUtils.states.open)
      )
    )    
    $('#snapshot').trigger('render', 'omnipostclicked')

    it('should have none state', ( ->
      $('#ui-omniPostCollapse').click()
      expect(testUtils.state).toEqual(testUtils.states.none)
      )
    ) 
   
  )
)

describe('autosize check', ( ->
    it('should have greater height than starting height', ( ->
      omnipost = testUtils.init()
      $('#ui-omniContainer').click()
      originalHeight = $('#ui-omniPostText').height()
      $('#ui-omniPostText').val('Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.')
      $(window).resize()
      newHeight = $('#ui-omniPostText').height()
      expect(originalHeight).not.toEqual(newHeight))
    )
    $.doTimeout(10, -> $('#snapshot').trigger('render', 'autosizetext'))
  )
)


