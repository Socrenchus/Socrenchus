(function() {
  var testUtils;

  testUtils = {
    state: 0,
    votetextVal: '',
    votecount: 0,
    states: {
      none: 0,
      up: 1,
      down: 2
    },
    defaultTestOptions: {
      id: 'votebox',
      selector: '#votebox',
      voteboxOptions: {
        local: true
      }
    },
    init: function(options) {
      var opts;
      testUtils.reset();
      opts = $.extend({}, testUtils.defaultTestOptions, options);
      $(opts.selector).votebox(opts.voteboxOptions);
      $(opts.selector).bind('upArrowPressed', testUtils.upArrowPressed);
      $(opts.selector).bind('downArrowPressed', testUtils.downArrowPressed);
      $(opts.selector).bind('votetextChanged', testUtils.votetextChanged);
      return $(opts.selector);
    },
    votetextChanged: function(event, params) {
      testUtils.votetextVal = params['votetext'];
      return testUtils.votecount = params['votecount'];
    },
    upArrowPressed: function(event, state) {
      return testUtils.state = state;
    },
    downArrowPressed: function(event, state) {
      return testUtils.state = state;
    },
    reset: function() {
      $(testUtils.defaultTestOptions.selector).unbind('upArrowPressed', testUtils.upArrowPressed);
      $(testUtils.defaultTestOptions.selector).unbind('downArrowPressed', testUtils.downArrowPressed);
      $(testUtils.defaultTestOptions.selector).unbind('votetextChanged', testUtils.votetextChanged);
      $(testUtils.defaultTestOptions.selector).remove();
      $('body').append($("<div id=" + testUtils.defaultTestOptions.id + "></div>"));
      testUtils.state = testUtils.states.none;
      testUtils.votetextVal = '';
      return testUtils.votecount = 0;
    }
  };

  describe('votebox unclicked', (function() {
    it('should have none state', (function() {
      var voteox;
      voteox = testUtils.init();
      return expect(testUtils.state).toEqual(testUtils.states.none);
    }));
    it('should have no text', (function() {
      return expect(testUtils.votetextVal).toEqual('');
    }));
    return $('#snapshot').trigger('render', 'noclick');
  }));

  describe('votebox up clicked', (function() {
    it('should have up state', (function() {
      var votebox;
      votebox = testUtils.init();
      votebox.find('#ui-upvote').click();
      return expect(testUtils.state).toEqual(testUtils.states.up);
    }));
    it('should have text equivalence to votes', (function() {
      return expect(testUtils.votetextVal).toEqual(testUtils.votecount);
    }));
    return $('#snapshot').trigger('render', 'upvoteclicked');
  }));

  describe('votebox down clicked', (function() {
    it('should have down state', (function() {
      var votebox;
      votebox = testUtils.init();
      votebox.find('#ui-downvote').click();
      return expect(testUtils.state).toEqual(testUtils.states.down);
    }));
    it('should have text equivalence to votes', (function() {
      return expect(testUtils.votetextVal).toEqual(testUtils.votecount);
    }));
    return $('#snapshot').trigger('render', 'downvoteclicked');
  }));

  describe('votebox down clicked 10 times and then up clicked 10 times', (function() {
    it('should have down state', (function() {
      var i, votebox;
      votebox = testUtils.init();
      for (i = 1; i <= 10; i++) {
        votebox.find('#ui-downvote').click();
      }
      for (i = 1; i <= 10; i++) {
        votebox.find('#ui-upvote').click();
      }
      return expect(testUtils.state).toEqual(testUtils.states.down);
    }));
    it('should have text equivalence to votes', (function() {
      return expect(testUtils.votetextVal).toEqual(testUtils.votecount);
    }));
    return $.doTimeout(10, function() {
      return $('#snapshot').trigger('render', 'downvote10clicked');
    });
  }));

}).call(this);
