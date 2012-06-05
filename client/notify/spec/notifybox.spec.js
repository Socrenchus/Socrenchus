(function() {
  var testUtils;

  testUtils = {
    state: 0,
    messages: [],
    messagecount: 0,
    states: {
      none: 0,
      open: 1
    },
    defaultTestOptions: {
      id: 'notify',
      selector: '#notify',
      notifyOptions: {}
    },
    init: function(options) {
      var opts;
      testUtils.reset();
      opts = $.extend({}, testUtils.defaultTestOptions, options);
      $(opts.selector).notify(opts);
      $(opts.selector).bind('notifyClicked', testUtils.setstate);
      $(opts.selector).bind('documentClicked', testUtils.setstate);
      $(opts.selector).bind('messagesadded', testUtils.setmessages);
      return $(opts.selector);
    },
    setstate: function(event, state) {
      testUtils.state = state;
      return alert('count ' + testUtils.state);
    },
    setmessages: function(event, params) {
      testUtils.messages = params['messages'];
      return testUtils.messagecount = params['messagecount'];
    },
    reset: function() {
      $(testUtils.defaultTestOptions.selector).unbind('notifyClicked', testUtils.setstate);
      $(testUtils.defaultTestOptions.selector).unbind('documentClicked', testUtils.setstate);
      $(testUtils.defaultTestOptions.selector).unbind('messagesadded', testUtils.setmessages);
      $(testUtils.defaultTestOptions.selector).remove();
      $('body').append($("<div id=" + testUtils.defaultTestOptions.id + "></div>"));
      testUtils.state = testUtils.states.none;
      testUtils.messages = [];
      return testUtils.messagecount = 0;
    }
  };

  describe('checking states', (function() {
    it('should have none state', (function() {
      var notify;
      notify = testUtils.init();
      return expect(testUtils.state).toEqual(testUtils.states.none);
    }));
    $('#snapshot').trigger('render', 'noclick');
    it('should have open state', (function() {
      var notify;
      notify = testUtils.init();
      notify.find('#notification-counter').click();
      return expect(testUtils.state).toEqual(testUtils.states.open);
    }));
    return $.doTimeout(1, function() {
      return $('#snapshot').trigger('render', 'click');
    });
  }));

  describe('checking messages', (function() {
    it('should have 1 message', (function() {
      var messages, notify;
      messages = [];
      messages.push('hello world');
      notify = testUtils.init({
        notificationCount: messages.length,
        messages: messages
      });
      return expect(testUtils.messagecount).toEqual(1);
    }));
    return $('#snapshot').trigger('render', '1message');
  }));

}).call(this);
