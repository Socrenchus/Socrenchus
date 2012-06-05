(function() {
  var testUtils;

  testUtils = {
    state: 0,
    panelCount: 0,
    states: {
      none: 0,
      open: 1
    },
    defaultTestOptions: {
      id: 'omnipost',
      selector: '#omnipost',
      voteboxOptions: {}
    },
    init: function(options) {
      var opts;
      testUtils.reset();
      opts = $.extend({}, testUtils.defaultTestOptions, options);
      $(opts.selector).omnipost(opts.voteboxOptions);
      $(opts.selector).bind('panelsChanged', testUtils.setPanelCount);
      $(opts.selector).bind('omnicontainerOpened', testUtils.setState);
      $(opts.selector).bind('linkpanelOpened', testUtils.setState);
      $(opts.selector).bind('videopanelOpened', testUtils.setState);
      $(opts.selector).bind('omnicontainerClosed', testUtils.setState);
      return $(opts.selector);
    },
    setState: function(event, state) {
      return testUtils.state = state;
    },
    setPanelCount: function(event, count) {
      return testUtils.panelCount = count;
    },
    reset: function() {
      $(testUtils.defaultTestOptions.selector).unbind('omnicontainerOpened', testUtils.setState);
      $(testUtils.defaultTestOptions.selector).unbind('linkpanelOpened', testUtils.setState);
      $(testUtils.defaultTestOptions.selector).unbind('videopanelOpened', testUtils.setState);
      $(testUtils.defaultTestOptions.selector).unbind('omnicontainerClosed', testUtils.setState);
      $(testUtils.defaultTestOptions.selector).remove();
      $('body').append($("<div id=" + testUtils.defaultTestOptions.id + "></div>"));
      testUtils.state = testUtils.states.none;
      return testUtils.currtag = '';
    }
  };

  describe('state check', (function() {
    it('should have none state', (function() {
      var omnipost;
      omnipost = testUtils.init();
      return expect(testUtils.state).toEqual(testUtils.states.none);
    }));
    $('#snapshot').trigger('render', 'nointeraction');
    it('should have open state', (function() {
      $('#ui-omniContainer').click();
      return expect(testUtils.state).toEqual(testUtils.states.open);
    }));
    $('#snapshot').trigger('render', 'omnipostclicked');
    return it('should have none state', (function() {
      $('#ui-omniPostCollapse').click();
      return expect(testUtils.state).toEqual(testUtils.states.none);
    }));
  }));

  describe('autosize check', (function() {
    it('should have greater height than starting height', (function() {
      var newHeight, omnipost, originalHeight;
      omnipost = testUtils.init();
      $('#ui-omniContainer').click();
      originalHeight = $('#ui-omniPostText').height();
      $('#ui-omniPostText').val('Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.');
      $(window).resize();
      newHeight = $('#ui-omniPostText').height();
      return expect(originalHeight).not.toEqual(newHeight);
    }));
    return $.doTimeout(10, function() {
      return $('#snapshot').trigger('render', 'autosizetext');
    });
  }));

}).call(this);
